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

	unit._movement_cache.setup(movement_callable, unit.get_unit_manager())

static func _init_behaviors(unit: Unit) -> void:
	unit.combat_behavior = UnitCombatBehaviorScript.new(unit)
	unit.movement_behavior = UnitMovementBehaviorScript.new(unit)
	unit.interaction_handler = UnitInteractionHandlerScript.new(unit)
	unit.death_handler = UnitDeathHandlerScript.new(unit)
	unit.query_service = UnitQueryServiceScript.new(unit)

static func _inject_dependencies(unit: Unit) -> void:
	var unit_manager := unit.get_unit_manager()
	if unit_manager:
		unit.set_unit_manager(unit_manager)

	var loot_manager := unit.get_loot_manager()
	if loot_manager:
		unit.set_loot_manager(loot_manager)

	var goal_manager := unit.get_goal_manager()
	if goal_manager:
		unit.set_goal_manager(goal_manager)

	var combat_system := unit.get_combat_system()
	if combat_system:
		unit.set_combat_system(combat_system)