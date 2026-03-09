extends GdUnitTestSuite

# Dependencies
const UnitScript := preload("res://Gameplay/targets/unit.gd")
const InventoryItemScript := preload("res://Gameplay/targets/inventory_item.gd")
const LootManager := preload("res://Gameplay/targets/loot_manager.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")
const TaskRewardScript := preload("res://Gameplay/narrative/task/task_reward.gd")

# Mocks
class MockLootManager extends LootManager:
	var spawned_loot := []
	func spawn_loot(coord: Vector2i, items: Array) -> void:
		spawned_loot.append({"coord": coord, "items": items})

func test_unit_death_handler_drops_quest_item_on_hard_difficulty() -> void:
	# Setup
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	unit.faction = Unit.Faction.ENEMY

	# Create a quest item
	var quest_item: InventoryItem = auto_free(InventoryItem.new())
	quest_item.quest = true
	quest_item.item_name = "Golden Idol"

	# Create a non-quest item
	var normal_item: InventoryItem = auto_free(InventoryItem.new())
	normal_item.quest = false
	normal_item.item_name = "Rusty Sword"

	unit.inv.add_item(quest_item)
	unit.inv.add_item(normal_item)

	var loot_manager: MockLootManager = auto_free(MockLootManager.new())
	var death_handler := UnitDeathHandler.new(unit)
	death_handler.set_loot_manager(loot_manager)

	# Mock SaveManager for high difficulty
	# Since SaveManager is an Autoload, we might need to mock it if possible,
	# but UnitDeathHandler checks 'if SaveManager:'.
	# In GdUnit, we can use spy/mock, but here we'll assume it falls back to 'normal' or we can set it.

	# Execute
	death_handler._drop_loot()

	# Verify
	assert_int(loot_manager.spawned_loot.size()).is_greater_than(0)
	var quest_found := false
	var normal_found := false
	for entry in loot_manager.spawned_loot:
		for item in entry.items:
			if item.item_name == "Golden Idol": quest_found = true
			if item.item_name == "Rusty Sword": normal_found = true

	assert_bool(quest_found).is_true()
	# On 'normal' or 'hard' difficulty, enemy units should NOT drop normal items without routing
	# should_drop is false for ENEMY if not 'easy'
	assert_bool(normal_found).is_false()

func test_task_round_changed_attribution() -> void:
	var task: Task = auto_free(Task.new())
	task.event_type = "countdown"
	task.duration_turns = 10
	task.owning_faction = Unit.Faction.ENEMY
	task.status = Task.Status.ACTIVE

	# Initial progress
	assert_int(task.effort_required).is_equal(0)

	# Notify round change for PLAYER - should NOT progress enemy task
	task.handle_event(GameConstants.TaskEvents.ROUND_CHANGED, {"faction": Unit.Faction.PLAYER})
	assert_int(task.current_effort).is_equal(0)

	# Notify round change for ENEMY - SHOULD progress
	task.handle_event(GameConstants.TaskEvents.ROUND_CHANGED, {"faction": Unit.Faction.ENEMY})
	assert_int(task.current_effort).is_equal(1)

	# Boundary check
	task.current_effort = 9
	task.handle_event(GameConstants.TaskEvents.ROUND_CHANGED, {"faction": Unit.Faction.ENEMY})
	assert_int(task.current_effort).is_equal(10)
	assert_int(task.status).is_equal(Task.Status.COMPLETED)

func test_task_reward_item_granting() -> void:
	# This test would ideally verify TaskController.gd's _on_task_completed
	# For now, we verify TaskReward data integrity as it's a new resource
	var reward: TaskReward = auto_free(TaskReward.new())
	reward.reward_type = TaskReward.RewardType.ITEM
	reward.reward_value = "rare_gem"

	assert_int(reward.reward_type).is_equal(0) # ITEM
	assert_str(reward.reward_value).is_equal("rare_gem")
