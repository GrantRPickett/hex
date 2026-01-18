extends GdUnitTestSuite

const CombatSystem = preload("res://Gameplay/combat_system.gd")
const Goal = preload("res://Gameplay/goal.gd")
const GoalManager = preload("res://Gameplay/goal_manager.gd")
const Loot = preload("res://Gameplay/loot.gd")
const LootManager = preload("res://Gameplay/loot_manager.gd")
const InventoryItem = preload("res://Resources/inventory_item.gd")

var unit: Unit

func before():
	unit = auto_free(Unit.new())
	add_child(unit)
	unit._ready()

func test_set_loot_manager():
	var loot_manager = Node.new()
	unit.set_loot_manager(loot_manager)
	# Cannot assert on private variable, but we can ensure it doesn't crash.

func test_set_goal_manager():
	var goal_manager = Node.new()
	unit.set_goal_manager(goal_manager)
	# Cannot assert on private variable, but we can ensure it doesn't crash.

func test_set_combat_system():
	var combat_system = Node.new()
	unit.set_combat_system(combat_system)
	# Cannot assert on private variable, but we can ensure it doesn't crash.

func test_attack_unit():
	var attacker = auto_free(Unit.new())
	add_child(attacker)
	attacker._ready()
	var defender = auto_free(Unit.new())
	add_child(defender)
	defender._ready()
	var combat_system_mock = auto_free(mock(CombatSystem))
	
	attacker.set_combat_system(combat_system_mock)
	attacker.global_position = Vector2(0, 0)
	defender.global_position = Vector2(1, 0) # Adjacent
	
	# Ensure attacker has an action
	attacker.refresh_turn()
	assert_true(attacker.has_action_available())

	# Stub the execute_combat method to do nothing
	stub(combat_system_mock, "execute_combat").to_do_nothing()

	# Call the method under test
	var result = attacker.attack_unit(defender)

	# Verifications
	assert_true(result)
	verify(combat_system_mock, "execute_combat").with(attacker, defender, 0).once()
	assert_false(attacker.has_action_available()) # Action should be consumed

func test_attack_unit_no_action_points():
	var attacker = auto_free(Unit.new())
	add_child(attacker)
	attacker._ready()
	var defender = auto_free(Unit.new())
	add_child(defender)
	defender._ready()
	var combat_system_mock = auto_free(mock(CombatSystem))

	attacker.set_combat_system(combat_system_mock)
	attacker.global_position = Vector2(0, 0)
	defender.global_position = Vector2(1, 0)

	# Consume the action
	attacker.refresh_turn()
	attacker.consume_action()
	assert_false(attacker.has_action_available())
	
	stub(combat_system_mock, "execute_combat").to_do_nothing()

	var result = attacker.attack_unit(defender)

	assert_false(result)
	verify(combat_system_mock, "execute_combat").never()

func test_work_on_goal():
	var worker = auto_free(Unit.new())
	add_child(worker)
	worker._ready()
	
	var goal = auto_free(Goal.new())
	add_child(goal)
	
	var goal_manager_mock = auto_free(mock(GoalManager))
	
	worker.set_goal_manager(goal_manager_mock)
	
	var goal_pos = Vector2(50, 50)
	worker.position = goal_pos
	goal.position = goal_pos
	
	worker.refresh_turn()
	assert_true(worker.has_action_available())
	
	stub(goal_manager_mock, "get_goal_count").to_return(1)
	stub(goal_manager_mock, "get_target").with(0).to_return(Vector2i(goal_pos))
	stub(goal_manager_mock, "apply_progress").to_do_nothing()
	
	var result = worker.work_on_goal(goal)
	
	assert_true(result)
	verify(goal_manager_mock, "apply_progress").with(0, worker).once()
	assert_false(worker.has_action_available())

func test_aid_ally():
	var aider = auto_free(Unit.new())
	add_child(aider)
	aider._ready()
	
	var ally = auto_free(Unit.new())
	add_child(ally)
	ally._ready()
	
	aider.global_position = Vector2(0, 0)
	ally.global_position = Vector2(1, 0) # Adjacent
	
	aider.refresh_turn()
	assert_true(aider.has_action_available())
	
	var initial_willpower = ally.willpower
	
	var result = aider.aid_ally(ally)
	
	assert_true(result)
	assert_int(ally.willpower).is_equal(initial_willpower + 1)
	assert_false(aider.has_action_available())

func test_loot():
	var looter = auto_free(Unit.new())
	add_child(looter)
	looter._ready()

	var loot_manager_mock = auto_free(mock(LootManager))
	looter.set_loot_manager(loot_manager_mock)

	var item = InventoryItem.new()
	item.item_name = "Test Item"
	
	var loot_object = auto_free(Loot.new())
	loot_object.inventory.append(item)

	var loot_coord = Vector2i(5, 5)
	looter.position = Vector2(loot_coord)

	looter.refresh_turn()
	assert_true(looter.has_action_available())

	stub(loot_manager_mock, "get_loot_at").with(loot_coord).to_return(loot_object)
	stub(loot_manager_mock, "remove_loot").to_do_nothing()

	var result = looter.loot(loot_coord)

	assert_true(result)
	assert_true(looter.get_inventory().get_items().has(item))
	verify(loot_manager_mock, "remove_loot").with(loot_object).once()
	assert_false(looter.has_action_available())

func test_apply_consumable():
	var consumer = auto_free(Unit.new())
	add_child(consumer)
	consumer._ready()
	
	var pair_index = 1
	var bonus = 5
	
	consumer.apply_consumable(pair_index, bonus)
	
	assert_true(consumer.consumables_active.has(pair_index))
	assert_int(consumer.consumables_active[pair_index]).is_equal(bonus)

func test_prepare_for_save():
	var unit_to_save = auto_free(Unit.new())
	add_child(unit_to_save)
	unit_to_save._ready()
	
	var item1 = auto_free(InventoryItem.new())
	item1.item_name = "Item 1"
	var item2 = auto_free(InventoryItem.new())
	item2.item_name = "Item 2"
	
	unit_to_save.get_inventory().equip_item(item1)
	unit_to_save.get_inventory().equip_item(item2)
	
	# Modify action points to see if it's copied
	unit_to_save.willpower = 5
	
	unit_to_save.prepare_for_save()
	
	assert_object(unit_to_save.action_points_template).is_not_null()
	assert_int(unit_to_save.action_points_template.get_willpower()).is_equal(5)
	assert_array(unit_to_save.saved_items).contains([item1, item2])
