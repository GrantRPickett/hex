extends GdUnitTestSuite

const TerrainMap := preload("res://Gameplay/terrain_map.gd")

var _spawned_nodes: Array[Node] = []

func _register(node: Node ) -> Node:
	if node != null:
		_spawned_nodes.append(node)
	return node

func _create_unit(position: Vector2 = Vector2.ZERO) -> Unit:
	var unit: Unit = Unit.new()
	unit._ready()
	unit.global_position = position
	_register(unit)
	return unit

func test_has_nearby_units_detects_units() -> void:
	var origin := _create_unit(Vector2.ZERO)
	var close_unit := _create_unit(Vector2(5, 0))
	var far_unit := _create_unit(Vector2(500, 0))

	var in_range := origin.get_units_in_range([close_unit, far_unit], 6.0)
	assert_array(in_range).has_size(1)
	assert_bool(origin.has_nearby_units([close_unit, far_unit], 6.0)).is_true()
	assert_bool(origin.has_nearby_units([far_unit], 6.0)).is_false()

func test_inventory_item_modifies_attributes() -> void:
	var unit := _create_unit()
	await get_tree().process_frame
	var item := InventoryItem.new() #resource or node?
	item.attribute_modifiers = {"grit": 2}

	var attributes := unit.get_attributes()
	assert_int(attributes.get_attribute("grit")).is_equal(6)
	assert_bool(unit.equip_item(item)).is_true()
	assert_int(attributes.get_attribute("grit")).is_equal(8)
	assert_bool(unit.unequip_item(item)).is_true()
	assert_int(attributes.get_attribute("grit")).is_equal(6)

func test_goals_in_range_and_acting() -> void:
	var unit := _create_unit(Vector2.ZERO)
	var goal: Node2D = _register(Node2D.new())
	goal.global_position = Vector2(5, 0)

	var goals := unit.list_goals_in_range([goal], 6.0)
	assert_array(goals).has_size(1)
	assert_bool(unit.act(goal)).is_true()
	goal.global_position = Vector2(500, 0)
	assert_bool(unit.act(goal)).is_false()

func test_attribute_helpers_and_inventory_accessors() -> void:
	var attributes := UnitAttributes.new()
	_register(attributes)
	attributes.set_base_attribute("gusto", 10)
	assert_int(attributes.get_base_attribute("gusto")).is_equal(10)
	attributes.apply_modifier("temp", {"gusto": -2})
	assert_int(attributes.get_attribute("gusto")).is_equal(8)
	attributes.remove_modifier("temp")
	assert_int(attributes.get_attribute("gusto")).is_equal(10)
	var snapshot := attributes.get_all_attributes()
	assert_that(snapshot.has("gusto")).is_true()

	var unit := _create_unit()
	unit.add_skill("dash")
	unit.add_skill("dash")
	assert_int(unit.skills.size()).is_equal(1)
	var inv := unit.get_inventory()
	assert_array(inv.get_items()).is_empty()

func test_range_helpers_cover_faction_and_morale() -> void:
	var origin := _create_unit(Vector2.ZERO)
	origin.max_willpower = 10
	origin.willpower = 10
	var ally := _create_unit(Vector2(1, 0))
	var enemy := _create_unit(Vector2(2, 0))
	enemy.faction = Unit.Faction.ENEMY
	var far_enemy := _create_unit(Vector2(50, 0))
	far_enemy.faction = Unit.Faction.ENEMY
	ally.max_willpower = 10
	ally.willpower = 5
	var adjacent := origin.get_adjacent_units([ally, enemy], 1.5)
	assert_bool(adjacent.has(ally)).is_true()
	assert_bool(adjacent.has(enemy)).is_false()
	var enemies := origin.get_units_in_range_by_faction([ally, enemy, far_enemy], 5.0, Unit.Faction.ENEMY)
	assert_bool(enemies.has(enemy)).is_true()
	assert_bool(enemies.has(far_enemy)).is_false()
	var morale_targets := origin.get_units_in_range_without_full_morale([ally, enemy], 5.0)
	assert_bool(morale_targets.has(ally)).is_true()
	assert_bool(morale_targets.has(enemy)).is_false()
	assert_bool(origin.is_at_full_morale()).is_true()
	origin.max_willpower = 10
	origin.willpower = 5
	assert_bool(origin.is_at_full_morale()).is_false()

func test_turn_state_methods_manage_resources() -> void:
	var unit := _create_unit()
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
	var unit := _create_unit()
	unit.refresh_turn()
	unit.apply_status_effect("poisoned")
	assert_bool(unit.has_status_effect("poisoned")).is_true()
	unit.clear_status_effect("poisoned")
	assert_bool(unit.has_status_effect("poisoned")).is_false()
	var terrain := TerrainTile.new()
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
	var wall := TerrainTile.new()
	_register(wall)
	wall.passable = false
	unit.on_enter_terrain(wall)
	assert_bool(unit.has_move_available()).is_false()

func test_compute_movement_range_accounts_for_terrain() -> void:
	var unit := _create_unit()
	unit.movement_points = 2
	var terrain_map := TerrainMap.new()
	terrain_map.load_from_rows(["GRM"], 3, 1) # G = Grass (cost 1), R = Road (cost 0.5), M = Mountain (cost 2)
	var reachable: Dictionary = unit.compute_movement_range(Vector2i(0, 0), terrain_map)
	assert_bool(reachable.has(Vector2i(1, 0))).is_true()
	assert_bool(reachable.has(Vector2i(2, 0))).is_false()

func after_test() -> void:
	for node in _spawned_nodes:
		if is_instance_valid(node):
			node.free()
	_spawned_nodes.clear()
