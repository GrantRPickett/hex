class_name UnitComponentFactory
extends RefCounted

const UnitCombatBehaviorScript := preload("res://Gameplay/components/unit_combat_behavior.gd")
const UnitMovementBehaviorScript := preload("res://Gameplay/components/unit_movement_behavior.gd")
const UnitInteractionHandlerScript := preload("res://Gameplay/components/unit_interaction_handler.gd")
const UnitDeathHandlerScript := preload("res://Gameplay/components/unit_death_handler.gd")
const UnitQueryServiceScript := preload("res://Gameplay/components/unit_query_service.gd")

const ActionPointsComponentResource := preload("res://Gameplay/components/action_points_component.gd")
const InventoryComponentResource := preload("res://Gameplay/components/inventory_component.gd")
const MovementRangeCacheResource := preload("res://Gameplay/components/movement_range_cache.gd")

static func create_components(unit: Unit) -> void:
	_init_action_points(unit)
	_init_inventory(unit)
	_init_movement_cache(unit)
	_init_behaviors(unit)
	_inject_dependencies(unit)

static func _init_action_points(unit: Unit) -> void:
	if unit.action_points_template == null:
		unit.action_points_template = ActionPointsComponentResource.new()

	unit._action_points = unit.action_points_template.duplicate(true)
	if unit._action_points == null:
		unit._action_points = ActionPointsComponentResource.new()

	# Apply pending values
	if unit._pending_max_willpower >= 0:
		unit._action_points.set_max_willpower(unit._pending_max_willpower)
	if unit._pending_willpower >= 0:
		unit._action_points.set_willpower(unit._pending_willpower)
	if unit._pending_movement_points >= 0:
		unit._action_points.set_movement_points(unit._pending_movement_points)

	# Reset pending
	unit._pending_willpower = -1
	unit._pending_max_willpower = -1
	unit._pending_movement_points = -1

	if unit.max_willpower < unit.willpower:
		unit.max_willpower = unit.willpower

	unit._action_points.refresh_turn()

static func _init_inventory(unit: Unit) -> void:
	if unit.inventory_component_template == null:
		unit.inventory_component_template = InventoryComponentResource.new()

	unit._inventory_component = unit.inventory_component_template.duplicate(true)
	if unit._inventory_component == null:
		unit._inventory_component = InventoryComponentResource.new()

	unit._inventory_component.setup(unit)

static func _init_movement_cache(unit: Unit) -> void:
	var movement_callable := func() -> int:
		return unit.movement_points

	if unit.movement_range_cache_template == null:
		unit.movement_range_cache_template = MovementRangeCacheResource.new()

	unit._movement_cache = unit.movement_range_cache_template.duplicate(true)
	if unit._movement_cache == null:
		unit._movement_cache = MovementRangeCacheResource.new()

	unit._movement_cache.setup(movement_callable)

static func _init_behaviors(unit: Unit) -> void:
	unit.combat_behavior = UnitCombatBehaviorScript.new(unit)
	unit.movement_behavior = UnitMovementBehaviorScript.new(unit)
	unit.interaction_handler = UnitInteractionHandlerScript.new(unit)
	unit.death_handler = UnitDeathHandlerScript.new(unit)
	unit.query_service = UnitQueryServiceScript.new(unit)

static func _inject_dependencies(unit: Unit) -> void:
	if not unit.unit_manager_path.is_empty() and unit.has_node(unit.unit_manager_path):
		var manager_node := unit.get_node(unit.unit_manager_path)
		if manager_node is UnitManager:
			unit.set_unit_manager(manager_node)

	if not unit.loot_manager_path.is_empty() and unit.has_node(unit.loot_manager_path):
		var loot_mgr := unit.get_node(unit.loot_manager_path)
		if loot_mgr is LootManager:
			unit.set_loot_manager(loot_mgr)

	if not unit.goal_manager_path.is_empty() and unit.has_node(unit.goal_manager_path):
		var goal_mgr := unit.get_node(unit.goal_manager_path)
		if goal_mgr is GoalManager:
			unit.set_goal_manager(goal_mgr)

	if not unit.combat_system_path.is_empty() and unit.has_node(unit.combat_system_path):
		var combat_sys := unit.get_node(unit.combat_system_path)
		if combat_sys is CombatSystem:
			unit.set_combat_system(combat_sys)