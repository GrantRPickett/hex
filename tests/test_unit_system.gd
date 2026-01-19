extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const _UnitScript := preload("res://Gameplay/unit.gd")
const _UnitManagerScript := preload("res://Gameplay/unit_manager.gd")
const LootManager := preload("res://Gameplay/loot_manager.gd")
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const CombatSystem := preload("res://Gameplay/combat_system.gd")
const ActionPointsComponentResource := preload("res://Gameplay/components/action_points_component.gd")
const InventoryComponentResource := preload("res://Gameplay/components/inventory_component.gd")
const UnitInventory := preload("res://Gameplay/unit_inventory.gd")
const MovementRangeCalculator := preload("res://Gameplay/movement_range_calculator.gd")
const MovementRangeCache := preload("res://Gameplay/components/movement_range_cache.gd")
const Goal := preload("res://Gameplay/goal.gd")


func _register(node: Node) -> Node:
	if node == null:
		return node
	return auto_free(node)

func _create_unit(position: Vector2 = Vector2.ZERO, unit_manager: UnitManager = null) -> Unit:
	var unit: Unit = Unit.new()
	if unit_manager:
		unit.set_unit_manager(unit_manager)
	unit._ready()
	unit.global_position = position
	_register(unit)
	return unit

func test_has_nearby_units_detects_units() -> void:
	var origin: Unit = _create_unit(Vector2.ZERO)
	var close_unit: Unit = _create_unit(Vector2(5, 0))
	var far_unit: Unit = _create_unit(Vector2(500, 0))

	var in_range: Array = origin.get_units_in_range([close_unit, far_unit], 6.0)
	assert_array(in_range).has_size(1)
	assert_bool(origin.has_nearby_units([close_unit, far_unit], 6.0)).is_true()
	assert_bool(origin.has_nearby_units([far_unit], 6.0)).is_false()

func test_inventory_item_modifies_attributes() -> void:
	var unit: Unit = _create_unit()
	await get_tree().process_frame
	var item: InventoryItem = InventoryItem.new() #resource or node?
	item.attribute_modifiers = {"grit": 2}

	var attributes: UnitAttributes = unit.get_attributes()
	assert_int(attributes.get_attribute("grit")).is_equal(6)
	assert_bool(unit.equip_item(item)).is_true()
	assert_int(attributes.get_attribute("grit")).is_equal(8)
	assert_bool(unit.unequip_item(item)).is_true()
	assert_int(attributes.get_attribute("grit")).is_equal(6)

func test_goals_in_range_and_acting() -> void:
	var unit: Unit = _create_unit(Vector2.ZERO)
	var goal: Node2D = _register(Node2D.new())
	goal.global_position = Vector2(5, 0)

	var goals: Array = unit.list_goals_in_range([goal], 6.0)
	assert_array(goals).has_size(1)
	assert_bool(unit.act(goal)).is_true()
	goal.global_position = Vector2(500, 0)
	assert_bool(unit.act(goal)).is_false()

func test_attribute_helpers_and_inventory_accessors() -> void:
	var attributes: UnitAttributes = UnitAttributes.new()
	_register(attributes)
	attributes.set_base_attribute("gusto", 10)
	assert_int(attributes.get_base_attribute("gusto")).is_equal(10)
	attributes.apply_modifier("temp", {"gusto": -2})
	assert_int(attributes.get_attribute("gusto")).is_equal(8)
	attributes.remove_modifier("temp")
	assert_int(attributes.get_attribute("gusto")).is_equal(10)
	var snapshot := attributes.get_all_attributes()
	assert_that(snapshot.has("gusto")).is_true()

	var unit: Unit = _create_unit()
	unit.add_skill("dash")
	unit.add_skill("dash")
	assert_int(unit.skills.size()).is_equal(1)
	var inv: UnitInventory = unit.get_inventory()
	assert_array(inv.get_items()).is_empty()

func test_range_helpers_cover_faction_and_morale() -> void:
	var origin: Unit = _create_unit(Vector2.ZERO)
	origin.max_willpower = 10
	origin.willpower = 10
	var ally: Unit = _create_unit(Vector2(1, 0))
	var enemy: Unit = _create_unit(Vector2(2, 0))
	enemy.faction = Unit.Faction.ENEMY
	var far_enemy: Unit = _create_unit(Vector2(50, 0))
	far_enemy.faction = Unit.Faction.ENEMY
	ally.max_willpower = 10
	ally.willpower = 5
	var adjacent: Array = origin.get_adjacent_units([ally, enemy], 1.5)
	assert_bool(adjacent.has(ally)).is_true()
	assert_bool(adjacent.has(enemy)).is_false()
	var enemies: Array = origin.get_units_in_range_by_faction([ally, enemy, far_enemy], 5.0, Unit.Faction.ENEMY)
	assert_bool(enemies.has(enemy)).is_true()
	assert_bool(enemies.has(far_enemy)).is_false()
	var morale_targets: Array = origin.get_units_in_range_without_full_morale([ally, enemy], 5.0)
	assert_bool(morale_targets.has(ally)).is_true()
	assert_bool(morale_targets.has(enemy)).is_false()
	assert_bool(origin.is_at_full_morale()).is_true()
	origin.max_willpower = 10
	origin.willpower = 5
	assert_bool(origin.is_at_full_morale()).is_false()

func test_turn_state_methods_manage_resources() -> void:
	var unit: Unit = _create_unit()
	unit.refresh_turn()
	assert_bool(unit.has_move_available()).is_true()
	assert_int(unit.get_remaining_movement_points()).is_equal(unit.movement_points)
	unit.consume_move(3)
	assert_int(unit.get_remaining_movement_points()).is_equal(unit.movement_points - 3)
	unit.consume_move(10)
	assert_int(unit.get_remaining_movement_points()).is_equal(0)
	assert_bool(unit.has_move_available()).is_false()
	unit.adjust_remaining_movement(2)
	assert_int(unit.get_remaining_movement_points()).is_equal(2)
	assert_bool(unit.has_move_available()).is_true()
	unit.block_movement_this_turn()
	assert_bool(unit.has_move_available()).is_false()
	unit.refresh_turn()
	assert_bool(unit.has_action_available()).is_true()
	unit.consume_action()
	assert_bool(unit.has_action_available()).is_false()
	unit.block_action_this_turn()
	assert_bool(unit.has_action_available()).is_false()

func test_status_effects_and_on_enter_terrain() -> void:
	var unit: Unit = _create_unit()
	unit.refresh_turn()
	unit.apply_status_effect("poisoned")
	assert_bool(unit.has_status_effect("poisoned")).is_true()
	unit.clear_status_effect("poisoned")
	assert_bool(unit.has_status_effect("poisoned")).is_false()
	var terrain: TerrainTile = TerrainTile.new()
	_register(terrain)
	terrain.movement_penalty = 2
	terrain.blocks_action_after_move = true
	terrain.status_effect = StringName("stuck")
	unit.on_enter_terrain(terrain)
	assert_int(unit.get_remaining_movement_points()).is_equal(unit.movement_points - 2)
	assert_bool(unit.has_action_available()).is_false()
	assert_bool(unit.has_status_effect("stuck")).is_true()
	unit.clear_status_effect("stuck")
	unit.refresh_turn()
	var wall: TerrainTile = TerrainTile.new()
	_register(wall)
	wall.passable = false
	unit.on_enter_terrain(wall)
	assert_bool(unit.has_move_available()).is_false()

func test_compute_movement_range_accounts_for_terrain() -> void:
	var unit: Unit = _create_unit()
	unit.movement_points = 2
	var terrain_map: TerrainMap = TerrainMap.new()
	terrain_map.load_from_rows(["GRM"], 3, 1) # G = Grass (cost 1), R = Road (cost 0.5), M = Mountain (cost 2)
	var reachable: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_bool(reachable.has(Vector2i(1, 0))).is_true()
	assert_bool(reachable.has(Vector2i(2, 0))).is_false()
	terrain_map.load_from_rows([])

func test_movement_range_cache_invalidates_on_changes() -> void:
	var unit_manager: UnitManager = _register(UnitManager.new())
	var unit: Unit = _create_unit(Vector2.ZERO, unit_manager)
	unit.movement_points = 3
	var terrain_map: TerrainMap = TerrainMap.new()
	terrain_map.load_from_rows(["GG"], 2, 1)
	var first: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	var second: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_that(first).is_equal(second)
	terrain_map.load_from_rows(["GM"], 2, 1)
	var third: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_that(third).is_not_equal(first)
	unit.movement_points = 4
	var fourth: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_that(fourth).is_not_equal(third)
	var fifth: Dictionary = unit.compute_movement_range(Vector2i(1, 0), terrain_map)
	assert_that(fifth).is_not_equal(fourth)
	unit_manager.unit_moved.emit(0, Vector2i(0, 0))
	var sixth: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_that(sixth).is_not_equal(fifth)
	terrain_map.load_from_rows([])

# ============================================================================
# Gameplay/unit.gd: set_loot_manager
# ============================================================================
func test_unit_set_loot_manager() -> void:
	# Given
	var unit: Unit = _create_unit()
	var loot_manager_instance = LootManager.new()
	_register(loot_manager_instance)

	# When
	unit.set_loot_manager(loot_manager_instance)

	# Then
	assert_object(unit.get_property("_loot_manager")).is_equal(loot_manager_instance)

# ============================================================================
# Gameplay/unit.gd: set_goal_manager
# ============================================================================
func test_unit_set_goal_manager() -> void:
	# Given
	var unit: Unit = _create_unit()
	var goal_manager_instance = GoalManager.new()
	_register(goal_manager_instance)

	# When
	unit.set_goal_manager(goal_manager_instance)

	# Then
	assert_object(unit.get_property("_goal_manager")).is_equal(goal_manager_instance)

# ============================================================================
# Gameplay/unit.gd: set_combat_system
# ============================================================================
func test_unit_set_combat_system() -> void:
	# Given
	var unit: Unit = _create_unit()
	var combat_system_instance = CombatSystem.new()
	_register(combat_system_instance)

	# When
	unit.set_combat_system(combat_system_instance)

	# Then
	assert_object(unit.get_property("_combat_system")).is_equal(combat_system_instance)

# ============================================================================
# Gameplay/unit.gd: work_on_goal
# ============================================================================
func test_unit_work_on_goal_consumes_action_and_applies_progress_no_mock() -> void:
	# Given
	var unit: Unit = _create_unit(Vector2i(1,1))
	var goal_instance = Goal.new()
	goal_instance.coord = Vector2i(1,1)
	_register(goal_instance)

	var goal_manager_instance = GoalManager.new()
	var grid_node = Node2D.new() # Dummy grid for setup
	_register(grid_node)

	# Setup GoalManager
	var goal_coords_array = [Vector2i(1,1)]
	var goals_array = [goal_instance]
	goal_manager_instance.setup(goal_coords_array, goals_array, grid_node)
	_register(goal_manager_instance) # Register if it's a Node and needs auto_free

	var action_points_component_instance = ActionPointsComponentResource.new()
	action_points_component_instance.max_actions = 1
	action_points_component_instance.actions_remaining = 1
	_register(action_points_component_instance)

	unit.set_goal_manager(goal_manager_instance)
	unit.set_property("_action_points", action_points_component_instance)
	unit.global_position = Vector2(100, 100) # Dummy position to make get_grid_location work if it maps global_position

	unit.faction = Unit.Faction.PLAYER # Set faction for progress tracking

	var initial_actions = action_points_component_instance.actions_remaining
	var initial_progress = goal_manager_instance.get_progress(0, unit.faction)

	# When
	var result = unit.work_on_goal(goal_instance)

	# Then
	assert_bool(result).is_true()
	assert_int(action_points_component_instance.actions_remaining).is_equal(initial_actions - 1)
	assert_int(goal_manager_instance.get_progress(0, unit.faction)).is_greater_than(initial_progress)

# ============================================================================
# Gameplay/unit.gd: get_path_to_coord
# ============================================================================
func test_unit_get_path_to_coord_returns_valid_path() -> void:
	# Given
	var unit: Unit = _create_unit(Vector2i(0,0))
	var target_coord = Vector2i(1,0) # Adjacent hex for a simple path
	var start_coord = Vector2i(0,0)

	var terrain_map_instance = TerrainMap.new()
	terrain_map_instance.load_from_rows(["GG"], 2, 1) # Simple 2x1 grid
	_register(terrain_map_instance)

	var movement_range_calculator_instance = MovementRangeCalculator.new()
	_register(movement_range_calculator_instance)

	# Unit's movement range
	unit.movement_points = 10
	unit.global_position = Vector2(0,0) # Ensure unit is at start_coord

	# When
	var path = unit.get_path_to_coord(target_coord, terrain_map_instance, start_coord)

	# Then
	assert_array(path).is_equal([target_coord]) # Expect a direct path

# ============================================================================
# Gameplay/unit.gd: apply_consumable
# ============================================================================
func test_unit_apply_consumable_updates_active_consumables() -> void:
	# Given
	var unit: Unit = _create_unit()
	var test_pair_index = 0
	var test_bonus = 10

	# When
	unit.apply_consumable(test_pair_index, test_bonus)

	# Then
	var consumables_active = unit.get_property("consumables_active")
	assert_dict(consumables_active).has_size(1)
	assert_int(consumables_active[test_pair_index]).is_equal(test_bonus)

# ============================================================================
# Gameplay/unit.gd: prepare_for_save
# ============================================================================
func test_unit_prepare_for_save_stores_action_points_and_items() -> void:
	# Given
	var unit: Unit = _create_unit()
	var action_points_component_instance = ActionPointsComponentResource.new()
	action_points_component_instance.actions_remaining = 5
	_register(action_points_component_instance)
	unit.set_property("_action_points", action_points_component_instance)

	var inventory_component_instance = InventoryComponentResource.new()
	_register(inventory_component_instance)
	var unit_inventory_instance = UnitInventory.new()
	unit_inventory_instance.add_item("Sword")
	unit_inventory_instance.add_item("Shield")
	_register(unit_inventory_instance)
	inventory_component_instance.set_inventory(unit_inventory_instance)
	unit.set_property("_inventory_component", inventory_component_instance)

	# When
	unit.prepare_for_save()

	# Then
	# A duplicated action_points_template should be a new instance but with same properties
	assert_object(unit.action_points_template).is_not_null()
	assert_object(unit.action_points_template).is_not_equal(action_points_component_instance)
	assert_int(unit.action_points_template.actions_remaining).is_equal(action_points_component_instance.actions_remaining)
	assert_array(unit.saved_items).is_equal(["Sword", "Shield"])