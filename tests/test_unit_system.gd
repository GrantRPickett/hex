extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/map/terrain_map.gd")
const _UnitScript := preload("res://Gameplay/targets/unit.gd")
const _UnitManagerScript := preload("res://Gameplay/targets/unit_manager.gd")
const LootManager := preload("res://Gameplay/targets/loot_manager.gd")
const TaskManager := preload("res://Gameplay/narrative/task/task_manager.gd")
const Skill := preload("res://Gameplay/skills/skill.gd")
const CombatSystem := preload("res://Gameplay/turn/combat_system.gd")
const ActionPointsComponentResource := preload("res://Gameplay/targets/components/action_points_component.gd")
const InventoryComponentResource := preload("res://Gameplay/targets/components/inventory_component.gd")
const UnitInventory := preload("res://Gameplay/targets/unit_inventory.gd")
const MovementRangeCalculator := preload("res://Gameplay/map/movement_range_calculator.gd")
const MovementRangeCache := preload("res://Gameplay/targets/components/movement_range_cache.gd")
const LocationClass := preload("res://Gameplay/targets/location.gd")
const TerrainTile := preload("res://Gameplay/terrain/terrain_tile.gd")
const ObjectiveClass := preload("res://Gameplay/narrative/task/objective.gd")
const StageClass := preload("res://Gameplay/narrative/task/stage.gd")
const TaskClass := preload("res://Gameplay/narrative/task/task.gd")


var _shared_grid: TileMapLayer

func _get_shared_grid() -> TileMapLayer:
	if _shared_grid == null:
		_shared_grid = auto_free(TileMapLayer.new())
		var tileset := TileSet.new()
		tileset.tile_size = Vector2i(16, 16)
		_shared_grid.tile_set = tileset
	return _shared_grid

func _create_unit(position: Vector2 = Vector2.ZERO, unit_manager: UnitManager = null) -> Unit:
	var unit: Unit = Unit.new()
	unit.grid_map = _get_shared_grid()

	if unit_manager:
		unit.set_unit_manager(unit_manager)

	add_child(unit)
	unit._ready()
	unit.global_position = position
	auto_free(unit)
	return unit

func _create_unit_with_saved_item(item: InventoryItem) -> Unit:
	var unit: Unit = Unit.new()
	item.equipped = true # Ensure it gets equipped during _ready
	unit.saved_items = [item]
	add_child(unit)
	unit._ready()
	auto_free(unit)
	return unit


func test_has_nearby_units_detects_units() -> void:
	var origin: Unit = _create_unit(Vector2.ZERO)
	var close_unit: Unit = _create_unit(Vector2(5, 0))
	var far_unit: Unit = _create_unit(Vector2(1000, 0))

	var in_range: Array = origin.query.get_units_in_range([close_unit, far_unit], 6.0)
	assert_array(in_range).has_size(1)
	assert_bool(origin.query.has_nearby_units([close_unit, far_unit], 6.0)).is_true()
	assert_bool(origin.query.has_nearby_units([far_unit], 6.0)).is_false()

func test_inventory_item_modifies_attributes() -> void:
	var unit: Unit = _create_unit()
	await get_tree().process_frame
	var item: InventoryItem = InventoryItem.new()
	var template := ItemTemplate.new()
	template.attribute_modifiers = {"grit": 2}
	item.template = template

	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GRIT)).is_equal(6)
	assert_bool(unit.inv.equip_item(item)).is_true()
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GRIT)).is_equal(8)
	assert_bool(unit.inv.unequip_item(item)).is_true()
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GRIT)).is_equal(6)

func test_locations_in_range_and_acting() -> void:
	var unit: Unit = _create_unit(Vector2.ZERO)
	var task_manager_instance: TaskManager = auto_free(TaskManager.new())
	unit.set_task_manager(task_manager_instance)

	# Set up a task so interaction succeeds
	var objective = auto_free(ObjectiveClass.new())
	var stage = auto_free(StageClass.new())
	var task = auto_free(TaskClass.new())
	task.status = TaskClass.Status.ACTIVE
	task.target_id = "test_loc"
	var typed_tasks: Array[Task] = [task]
	stage.active_tasks.assign(typed_tasks)
	objective.current_stage = stage
	task_manager_instance._active_objective = objective

	var loc: Location = auto_free(LocationClass.new())
	loc.loc_name = "test_loc"
	task_manager_instance.register_location(loc)
	loc.global_position = Vector2(5, 0)

	var locations: Array = unit.query.list_locations_in_range([loc], 6.0)
	assert_array(locations).has_size(1)
	assert_bool(unit.interaction.interact(loc)).is_true()
	loc.global_position = Vector2(1000, 0)
	assert_bool(unit.interaction.interact(loc)).is_false()

func test_attribute_helpers_and_inventory_accessors() -> void:
	var unit: Unit = _create_unit()
	unit.gusto = 10
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GUSTO)).is_equal(10)
	unit.apply_attribute_modifier("temp", {GameConstants.Attributes.GUSTO: - 2})
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GUSTO)).is_equal(8)
	unit.remove_attribute_modifier("temp")
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GUSTO)).is_equal(10)

	var dash_skill := Skill.new()
	unit.add_skill(dash_skill)
	unit.add_skill(dash_skill)
	assert_int(unit.skills.size()).is_equal(1)
	var unit_inv: UnitInventory = unit.inv.get_inventory()
	assert_array(unit_inv.get_items()).is_empty()

func test_unit_attributes_preserve_scene_values() -> void:
	var scene: PackedScene = load("res://Resources/characters/core/assassin.tscn")
	var unit: Unit = auto_free(scene.instantiate())
	unit._ready()
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.SHADE)).is_equal(9)
	assert_int(unit.get_attribute_by_name(GameConstants.Attributes.GRIT)).is_equal(3)

func test_range_helpers_cover_faction_and_morale() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var origin: Unit = _create_unit(Vector2.ZERO, unit_manager)
	origin.res.max_willpower = 10
	origin.res.willpower = 10
	var ally: Unit = _create_unit(Vector2.ZERO, unit_manager)
	var enemy: Unit = _create_unit(Vector2.ZERO, unit_manager)
	enemy.faction = Unit.Faction.ENEMY
	var far_enemy: Unit = _create_unit(Vector2.ZERO, unit_manager)
	far_enemy.faction = Unit.Faction.ENEMY

	unit_manager.add_unit(origin, Vector2i(0, 0))
	unit_manager.add_unit(ally, Vector2i(1, 0))
	unit_manager.add_unit(enemy, Vector2i(10, 10))
	unit_manager.add_unit(far_enemy, Vector2i(20, 20))

	ally.res.max_willpower = 10
	ally.res.willpower = 5

	var adjacent: Array = origin.query.get_adjacent_units([ally, enemy], 1.5)
	assert_bool(adjacent.has(ally)).is_true()
	assert_bool(adjacent.has(enemy)).is_false()

	var enemies: Array = origin.query.get_units_in_range_by_faction([ally, enemy, far_enemy], 100.0, Unit.Faction.ENEMY)
	assert_bool(enemies.has(enemy)).is_true()
	assert_bool(enemies.has(far_enemy)).is_true()

	var morale_targets: Array = origin.get_units_in_range_without_full_morale([ally, enemy], 100.0)
	assert_bool(morale_targets.has(ally)).is_true()
	assert_bool(morale_targets.has(enemy)).is_false()
	assert_bool(origin.is_at_full_morale()).is_true()
	origin.res.max_willpower = 10
	origin.res.willpower = 5
	assert_bool(origin.is_at_full_morale()).is_false()

func test_turn_state_methods_manage_resources() -> void:
	var unit: Unit = _create_unit()
	unit.refresh_for_new_round()
	assert_bool(unit.res.has_move_available()).is_true()
	assert_int(unit.res.get_remaining_movement_points()).is_equal(unit.res.get_movement_points())
	unit.res.consume_move(3)
	assert_int(unit.res.get_remaining_movement_points()).is_equal(unit.res.get_movement_points() - 3)
	unit.res.consume_move(10)
	assert_int(unit.res.get_remaining_movement_points()).is_equal(0)
	assert_bool(unit.res.has_move_available()).is_false()
	unit.res.adjust_remaining_movement(2)
	assert_int(unit.res.get_remaining_movement_points()).is_equal(2)
	assert_bool(unit.res.has_move_available()).is_true()
	unit.block_movement_this_turn()
	assert_bool(unit.res.has_move_available()).is_false()
	unit.refresh_for_new_round()
	assert_bool(unit.res.has_action_available()).is_true()
	unit.res.consume_action()
	assert_bool(unit.res.has_action_available()).is_false()
	unit.block_action_this_turn()
	assert_bool(unit.res.has_action_available()).is_false()


func test_status_effects_and_on_enter_terrain() -> void:
	var unit: Unit = _create_unit()
	unit.refresh_for_new_round()
	unit.status.apply_status_effect("poisoned")
	assert_bool(unit.status.has_status_effect("poisoned")).is_true()
	unit.status.clear_status_effect("poisoned")
	assert_bool(unit.status.has_status_effect("poisoned")).is_false()
	var terrain: TerrainTile = auto_free(TerrainTile.new())
	terrain.movement_penalty = 2
	terrain.blocks_action_after_move = true
	terrain.status_effect = StringName("stuck")
	unit.on_enter_terrain(terrain)
	assert_int(unit.res.get_remaining_movement_points()).is_equal(unit.res.get_movement_points() - 2)
	assert_bool(unit.res.has_action_available()).is_false()
	assert_bool(unit.status.has_status_effect("stuck")).is_true()
	unit.status.clear_status_effect("stuck")
	unit.refresh_for_new_round()
	var wall: TerrainTile = auto_free(TerrainTile.new())
	wall.passable = false
	unit.on_enter_terrain(wall)
	assert_bool(unit.res.has_move_available()).is_false()

func test_compute_movement_range_accounts_for_terrain() -> void:
	var unit: Unit = _create_unit()
	unit.res.set_movement_points(2)
	unit.refresh_for_new_round()
	var terrain_map: TerrainMap = auto_free(TerrainMap.new())
	terrain_map.load_from_rows(["GGM"], 3, 1) # G cost 1, G cost 1, M cost 2
	var reachable: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_bool(reachable.has(Vector2i(1, 0))).is_true()
	assert_bool(reachable.has(Vector2i(2, 0))).is_false()

func test_movement_range_cache_invalidates_on_changes() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = _create_unit(Vector2.ZERO, unit_manager)
	unit.res.set_movement_points(3)
	unit.refresh_for_new_round()
	var terrain_map: TerrainMap = auto_free(TerrainMap.new())
	terrain_map.load_from_rows(["GG"], 2, 1)
	var first: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map).duplicate()
	assert_bool(first.is_empty()).is_false()
	var second: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map).duplicate()
	assert_that(first).is_equal(second)

	# Change map -> Invalidate (manual if map doesn't emit, but here we just re-load)
	terrain_map.load_from_rows(["GM"], 2, 1)
	unit._movement_cache.invalidate()
	var third: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map).duplicate()
	assert_that(third).is_not_equal(first)

	# Change MP -> Invalidate
	unit.res.set_movement_points(4)
	unit.refresh_for_new_round()
	var fourth: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map).duplicate()
	assert_that(fourth).is_not_equal(third)

	# Change Start Coord -> Different result
	var fifth: Dictionary = unit.movement.compute_movement_range(Vector2i(1, 0), terrain_map).duplicate()
	assert_that(fifth).is_not_equal(fourth)

	# Signal from manager -> Invalidate
	unit_manager.unit_moved.emit(0, Vector2i(0, 0))
	var sixth: Dictionary = unit.movement.compute_movement_range(Vector2i(0, 0), terrain_map).duplicate()
	assert_bool(sixth.is_empty()).is_false()

# ============================================================================
# Gameplay/unit.gd: set_loot_manager
# ============================================================================
func test_unit_set_loot_manager() -> void:
	# Given
	var unit: Unit = _create_unit()
	var loot_manager_instance = auto_free(LootManager.new())

	# When
	unit.set_loot_manager(loot_manager_instance)

	# Then
	assert_object(unit.get_loot_manager()).is_equal(loot_manager_instance)

# ============================================================================
# Gameplay/unit.gd: set_task_manager
# ============================================================================
func test_unit_set_task_manager() -> void:
	# Given
	var unit: Unit = _create_unit()
	var task_manager_instance = auto_free(TaskManager.new())

	# When
	unit.set_task_manager(task_manager_instance)

	# Then
	assert_object(unit.get_task_manager()).is_equal(task_manager_instance)

# ============================================================================
# Gameplay/unit.gd: set_combat_system
# ============================================================================
func test_unit_set_combat_system() -> void:
	# Given
	var unit: Unit = _create_unit()
	var combat_system_instance = auto_free(CombatSystem.new())

	# When
	unit.set_combat_system(combat_system_instance)

	# Then
	assert_object(unit.get_combat_system()).is_equal(combat_system_instance)

# ============================================================================
# Gameplay/unit_component_factory.gd: dependency injection
# ============================================================================
func test_unit_components_receive_injected_dependencies() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var loot_manager: LootManager = auto_free(LootManager.new())
	var task_manager: TaskManager = auto_free(TaskManager.new())
	var combat_system: CombatSystem = auto_free(CombatSystem.new())
	var unit: Unit = auto_free(Unit.new())

	unit._ready() # Initialize components

	# Inject dependencies AFTER _ready so components are non-null
	unit.set_unit_manager(unit_manager)
	unit.set_loot_manager(loot_manager)
	unit.set_task_manager(task_manager)
	unit.set_combat_system(combat_system)

	assert_object(unit._movement_cache._unit_manager).is_equal(unit_manager)
	assert_object(unit.death._unit_manager).is_equal(unit_manager)
	assert_object(unit.death._loot_manager).is_equal(loot_manager)
	assert_object(unit.interaction._loot_manager).is_equal(loot_manager)
	assert_object(unit.interaction._task_manager).is_equal(task_manager)
	assert_object(unit.combat._combat_system).is_equal(combat_system)

# ============================================================================
# Gameplay/unit.gd: work_on_task
# ============================================================================
func test_unit_work_on_task_consumes_action_and_applies_progress_no_mock() -> void:
	# Given
	var unit: Unit = _create_unit()
	var location_coord := Vector2i(1, 1)

	# Set up a mock grid so the unit knows its location
	var grid: TileMapLayer = auto_free(TileMapLayer.new())
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	grid.tile_set = tileset
	unit.grid_map = grid
	unit.position = grid.map_to_local(location_coord)

	# Set up the location and task manager
	var task_manager_instance: TaskManager = auto_free(TaskManager.new())
	var loc: Location = auto_free(LocationClass.new())
	loc.coord = location_coord
	loc.loc_name = "test_loc"
	task_manager_instance.register_location(loc)
	unit.set_task_manager(task_manager_instance)

	# Set up task
	var objective = auto_free(ObjectiveClass.new())
	var stage = auto_free(StageClass.new())
	var task = auto_free(TaskClass.new())
	task.status = TaskClass.Status.ACTIVE
	task.target_id = "test_loc"
	var typed_tasks: Array[Task] = [task]
	stage.active_tasks.assign(typed_tasks)
	objective.current_stage = stage
	task_manager_instance._active_objective = objective

	# Set up action points
	unit.faction = Unit.Faction.PLAYER
	unit.refresh_for_new_round()

	# When
	var result = unit.interaction.interact(loc)

	# Then
	assert_bool(result).is_true()
	assert_bool(unit.res.has_action_available()).is_false()

func test_unit_get_path_to_coord_returns_valid_path() -> void:
	# Given
	var unit: Unit = _create_unit(Vector2i(0, 0))
	var terrain_map_instance = auto_free(TerrainMap.new())
	terrain_map_instance.load_from_rows(["GGG", "GGG"], 3, 2)

	unit.res.set_movement_points(10)
	unit.refresh_for_new_round()
	unit.global_position = Vector2(0, 0)

	# When
	var path = unit.movement.get_path_to_coord(Vector2i(2, 0), terrain_map_instance, Vector2i(0, 0))

	# Then
	assert_array(path).is_not_empty()

func test_unit_get_path_to_coord_prefers_lower_cost_route() -> void:
	# Given
	var unit: Unit = _create_unit(Vector2i(0, 0))
	var target_coord = Vector2i(1, 1)

	var terrain_map_instance = auto_free(TerrainMap.new())
	terrain_map_instance.load_from_rows(["GM", "GG"], 2, 2)

	unit.res.set_movement_points(6)
	unit.refresh_for_new_round()
	var movement_budget = 4

	# When
	var weighted_path = unit.movement.get_path_to_coord(target_coord, terrain_map_instance, Vector2i(0, 0), movement_budget)

	# Then
	assert_array(weighted_path).is_equal([Vector2i(0, 1), target_coord])

func test_unit_get_path_to_coord_prefers_shorter_path_on_equal_cost() -> void:
	# Given
	var unit: Unit = _create_unit(Vector2i(0, 0))
	var target_coord = Vector2i(0, 2)

	var terrain_map_instance = auto_free(TerrainMap.new())
	terrain_map_instance.load_from_rows(["GG", "MG", "GG"], 2, 3)

	unit.res.set_movement_points(8)
	unit.refresh_for_new_round()
	var movement_budget = 8

	# When
	var tie_broken_path = unit.movement.get_path_to_coord(target_coord, terrain_map_instance, Vector2i(0, 0), movement_budget)

	# Then
	assert_array(tie_broken_path).is_equal([Vector2i(0, 1), target_coord])

func test_unit_apply_consumable_updates_active_consumables() -> void:
	var unit: Unit = _create_unit()
	unit.apply_consumable(0, 10)
	assert_dict(unit.consumables_active).has_size(1)
	assert_int(unit.consumables_active[0]).is_equal(10)

func test_unit_prepare_for_save_stores_action_points_and_items() -> void:
	var unit: Unit = _create_unit()
	unit.res.set_movement_points(5)
	var item := InventoryItem.new()
	var template := ItemTemplate.new()
	template.item_name = "Sword"
	item.template = template
	unit.inv.equip_item(item)

	unit.prepare_for_save()

	assert_object(unit.action_points_template).is_not_null()
	assert_int(unit.action_points_template.movement_points).is_equal(5)
	assert_array(unit.saved_items).has_size(1)

func test_set_free_roam_mode_prevents_action_and_move_consumption() -> void:
	var unit: Unit = _create_unit()
	unit.set_free_roam_mode(true)
	assert_bool(unit.is_in_free_roam_mode()).is_true()
	unit.movement.consume_move(5)
	# In free roam, remaining move points are kept at MAX
	assert_int(unit.movement.get_remaining_movement_points()).is_equal(Unit.FREE_ROAM_MOVEMENT_POINTS)
	unit.consume_action()
	assert_bool(unit.res.has_action_available()).is_true()

func test_unit_saved_items_produce_unique_instances_per_unit() -> void:
	var shared_item: InventoryItem = load("res://Resources/items/bronze_grit.tres") as InventoryItem
	var first: Unit = _create_unit_with_saved_item(shared_item)
	var second: Unit = _create_unit_with_saved_item(shared_item)
	var first_items: Array = first.inv.get_equipped_items()
	var second_items: Array = second.inv.get_equipped_items()
	assert_array(first_items).has_size(1)
	assert_array(second_items).has_size(1)
	assert_object(first_items[0]).is_not_equal(second_items[0])

func test_unit_get_path_to_coord_blocks_occupied_hexes() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = _create_unit(Vector2i(0, 0), unit_manager)
	unit.faction = Unit.Faction.PLAYER
	var blocker: Unit = _create_unit(Vector2i(0, 0), unit_manager)
	blocker.faction = Unit.Faction.ENEMY
	unit_manager.add_unit(unit, Vector2i(0, 0))
	unit_manager.add_unit(blocker, Vector2i(0, 1))

	# 1x3 map so blocker MUST be passed
	var terrain_map_instance = auto_free(TerrainMap.new())
	terrain_map_instance.load_from_rows(["G", "G", "G"], 1, 3)

	unit.res.set_movement_points(5)
	unit.refresh_for_new_round()

	# target (0,2) is behind blocker (0,1)
	var path = unit.movement.get_path_to_coord(Vector2i(0, 2), terrain_map_instance, Vector2i(0, 0))
	assert_array(path).is_empty()

func test_unit_get_path_to_coord_allows_friendly_hexes() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var unit: Unit = _create_unit(Vector2i(0, 0), unit_manager)
	unit.faction = Unit.Faction.PLAYER
	var ally: Unit = _create_unit(Vector2i(0, 0), unit_manager)
	ally.faction = Unit.Faction.PLAYER
	unit_manager.add_unit(unit, Vector2i(0, 0))
	unit_manager.add_unit(ally, Vector2i(0, 1))

	var terrain_map_instance = auto_free(TerrainMap.new())
	terrain_map_instance.load_from_rows(["G", "G", "G"], 1, 3)

	unit.res.set_movement_points(5)
	unit.refresh_for_new_round()
	var path = unit.movement.get_path_to_coord(Vector2i(0, 2), terrain_map_instance, Vector2i(0, 0))
	assert_array(path).is_equal([Vector2i(0, 1), Vector2i(0, 2)])
