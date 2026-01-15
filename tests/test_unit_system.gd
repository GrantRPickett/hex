extends GdUnitTestSuite

var _spawned_nodes: Array[Node] = []

func _register(node: Node) -> Node:
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
	var item := InventoryItem.new()
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

func after_test() -> void:
	for node in _spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_spawned_nodes.clear()
