extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/map/terrain_map.gd")
const InventoryComponent := preload("res://Gameplay/targets/components/inventory_component.gd")
const ActionPointsComponent := preload("res://Gameplay/targets/components/action_points_component.gd")
const MovementRangeCache := preload("res://Gameplay/targets/components/movement_range_cache.gd")
const InventoryItem := preload("res://Gameplay/targets/inventory_item.gd")
const UnitManager := preload("res://Gameplay/targets/unit_manager.gd")
const UnitMovementBehavior := preload("res://Gameplay/targets/components/unit_movement_behavior.gd")

func _register(node):
	if node == null:
		return node
	return auto_free(node)


func test_action_points_component_tracks_turn_state() -> void:
	var component: ActionPointsComponent = ActionPointsComponent.new()
	component.set_max_willpower(12)
	component.set_willpower(8)
	component.set_movement_points(5)
	component.refresh_for_new_round()
	assert_bool(component.has_move_available()).is_true()
	assert_int(component.get_remaining_movement_points()).is_equal(5)
	component.consume_move(3)
	assert_int(component.get_remaining_movement_points()).is_equal(2)
	component.adjust_remaining_movement(-1)
	assert_int(component.get_remaining_movement_points()).is_equal(1)
	component.block_movement_this_turn()
	assert_bool(component.has_move_available()).is_false()
	component.refresh_for_new_round()
	component.consume_action()
	assert_bool(component.has_action_available()).is_false()
	component.block_action_this_turn()
	assert_bool(component.has_action_available()).is_false()
	assert_int(component.get_movement_points()).is_equal(5)
	assert_int(component.get_willpower()).is_equal(8)
	assert_int(component.get_max_willpower()).is_equal(12)

func test_inventory_component_applies_item_modifiers() -> void:
	var unit_scene: Resource = load("res://Gameplay/scene_templates/generic_unit.tscn")
	var unit: Unit = _register(unit_scene.instantiate() as Unit)
	unit.unit_name = "Test Hero"
	unit.grit = 6
	
	# Components are created in _ready or can be forced
	UnitComponentFactory.create_components(unit)
	
	var item: InventoryItem = InventoryItem.new()
	item.template = ItemTemplate.new()
	item.template.attribute_modifiers = {"grit": 1}
	
	assert_bool(unit.inv.equip_item(item)).is_true()
	assert_int(unit.get_attribute(GameConstants.AttributeIndex.GRIT)).is_equal(7)
	
	assert_bool(unit.inv.unequip_item(item)).is_true()
	assert_int(unit.get_attribute(GameConstants.AttributeIndex.GRIT)).is_equal(6)
	
	unit.inv.cleanup()


func test_set_start_of_turn_grid_coord_updates_anchor() -> void:
	var behavior: UnitMovementBehavior = UnitMovementBehavior.new(null)
	var anchor := Vector2i(3, 4)
	behavior.set_start_of_turn_grid_coord(anchor)
	assert_that(behavior.get_start_of_turn_grid_coord()).is_equal(anchor)

func test_movement_range_cache_reacts_to_unit_manager() -> void:
	var movement_points := 3
	var cache: MovementRangeCache = _register(MovementRangeCache.new())
	cache.setup(func() -> int:
		return movement_points
	)
	var terrain_map: TerrainMap = _register(TerrainMap.new())
	terrain_map.load_from_rows(["GG"], 2, 1)
	var first: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	var second: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	assert_that(first).is_equal(second)
	movement_points = 1
	var third: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	assert_that(third).is_equal(first)
	cache.invalidate()
	var manager: UnitManager = _register(UnitManager.new())
	cache.set_unit_manager(manager)
	movement_points = 5
	cache.compute_range(Vector2i(0, 0), terrain_map)
	manager.unit_moved.emit(0, Vector2i(0, 0))
	var refreshed: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	assert_that(refreshed).is_not_equal(third)
	movement_points = 2
	var cached_again: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	assert_that(cached_again).is_equal(refreshed)
	manager.unit_moved.emit(0, Vector2i(0, 0))
	var final_result: Dictionary = cache.compute_range(Vector2i(0, 0), terrain_map)
	assert_that(final_result).is_not_equal(refreshed)
	cache.cleanup()

func test_inventory_component_item_management() -> void:
	var unit: Unit = _register(Unit.new())
	var component: InventoryComponent = InventoryComponent.new()
	component.setup(unit)
	
	var item: InventoryItem = InventoryItem.new()
	item.origin_id = "test_item"
	
	assert_that(component.add_item_to_inventory(item)).is_true()
	assert_that(component.has_item_by_id("test_item")).is_true()
	assert_that(component.has_item_by_id("other_item")).is_false()
	
	assert_that(component.remove_item_from_inventory(item)).is_true()
	assert_that(component.has_item_by_id("test_item")).is_false()
	
	component.cleanup()
