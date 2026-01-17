extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const InventoryComponent := preload("res://Gameplay/components/inventory_component.gd")
const ActionPointsComponent := preload("res://Gameplay/components/action_points_component.gd")
const MovementRangeCache := preload("res://Gameplay/components/movement_range_cache.gd")
const InventoryItem := preload("res://Resources/inventory_item.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")

func _register(node):
	if node == null:
		return node
	return auto_free(node)


func test_action_points_component_tracks_turn_state() -> void:
	var component: ActionPointsComponent = ActionPointsComponent.new()
	component.set_max_willpower(12)
	component.set_willpower(8)
	component.set_movement_points(5)
	component.refresh_turn()
	assert_bool(component.has_move_available()).is_true()
	assert_int(component.get_remaining_movement_points()).is_equal(5)
	component.consume_move(3)
	assert_int(component.get_remaining_movement_points()).is_equal(2)
	component.adjust_remaining_movement(-1)
	assert_int(component.get_remaining_movement_points()).is_equal(1)
	component.block_movement_this_turn()
	assert_bool(component.has_move_available()).is_false()
	component.refresh_turn()
	component.consume_action()
	assert_bool(component.has_action_available()).is_false()
	component.block_action_this_turn()
	assert_bool(component.has_action_available()).is_false()
	assert_int(component.get_movement_points()).is_equal(5)
	assert_int(component.get_willpower()).is_equal(8)
	assert_int(component.get_max_willpower()).is_equal(12)

func test_inventory_component_applies_item_modifiers() -> void:
	var owner: Node2D = _register(Node2D.new())
	var component: InventoryComponent = InventoryComponent.new()
	component.setup(owner)
	var attributes: UnitAttributes = component.get_attributes()
	var inventory: UnitInventory = component.get_inventory()
	var item: InventoryItem = InventoryItem.new()
	item.attribute_modifiers = {"grit": 1}
	assert_bool(component.equip_item(item)).is_true()
	assert_int(attributes.get_attribute("grit")).is_equal(7)
	assert_bool(component.unequip_item(item)).is_true()
	component.cleanup()

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
