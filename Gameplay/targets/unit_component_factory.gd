class_name UnitComponentFactory
extends RefCounted

static func create_components(unit: Unit) -> void:
	_init_action_points(unit)
	_init_inventory(unit)
	_init_movement_cache(unit)
	_init_behaviors(unit)
	_inject_dependencies(unit)

static func _init_action_points(unit: Unit) -> void:
	if unit.action_points_template == null:
		unit.action_points_template = ActionPointsComponent.new()

	unit._action_points = unit.action_points_template.duplicate(true)
	if unit._action_points == null:
		unit._action_points = ActionPointsComponent.new()

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

	unit._action_points.refresh_for_new_round()

static func _init_inventory(unit: Unit) -> void:
	if unit.inventory_component_template == null:
		unit.inventory_component_template = InventoryComponent.new()

	unit._inventory_component = unit.inventory_component_template.duplicate(true)
	if unit._inventory_component == null:
		unit._inventory_component = InventoryComponent.new()

	unit._inventory_component.setup(unit)

static func _init_movement_cache(unit: Unit) -> void:
	var movement_callable := func() -> int:
		return unit.movement_points

	if unit.movement_range_cache_template == null:
		unit.movement_range_cache_template = MovementRangeCache.new()

	unit._movement_cache = unit.movement_range_cache_template.duplicate(true)
	if unit._movement_cache == null:
		unit._movement_cache = MovementRangeCache.new()

	unit._movement_cache.setup(movement_callable, unit.get_unit_manager())

static func _init_behaviors(unit: Unit) -> void:
	unit.combat_behavior = UnitCombatBehavior.new(unit)
	unit.movement_behavior = UnitMovementBehavior.new(unit)
	unit.interaction_handler = UnitInteractionHandler.new(unit)
	unit.death_handler = UnitDeathHandler.new(unit)
	unit.query_service = UnitQueryService.new(unit)
	unit.loyalty_component = UnitLoyaltyComponent.new(unit)
	unit.status_component = UnitStatusComponent.new(unit)

static func _inject_dependencies(unit: Unit) -> void:
	var unit_manager := unit.get_unit_manager()
	if unit_manager:
		unit.set_unit_manager(unit_manager)

	var loot_manager := unit.get_loot_manager()
	if loot_manager:
		unit.set_loot_manager(loot_manager)

	var combat_system := unit.get_combat_system()
	if combat_system:
		unit.set_combat_system(combat_system)
