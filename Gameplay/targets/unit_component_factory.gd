class_name UnitComponentFactory
extends RefCounted

static func create_components(unit: Unit) -> void:
	_init_inventory(unit)
	_init_movement_cache(unit)
	_init_threat_cache(unit)
	_init_behaviors(unit)
	_inject_dependencies(unit)

static func _init_inventory(unit: Unit) -> void:
	if unit.inventory_component_template == null:
		unit.inventory_component_template = InventoryComponent.new()

	unit.inv = unit.inventory_component_template.duplicate(true)
	if unit.inv == null:
		unit.inv = InventoryComponent.new()

	unit.inv.setup(unit)
  
static func _init_movement_cache(unit: Unit) -> void:
	var movement_callable := func() -> int:
		return unit.movement_points

	if unit.movement_range_cache_template == null:
		unit.movement_range_cache_template = MovementRangeCache.new()

	unit._movement_cache = unit.movement_range_cache_template.duplicate(true)
	if unit._movement_cache == null:
		unit._movement_cache = MovementRangeCache.new()

	unit._movement_cache.setup(movement_callable, unit.get_unit_manager())

static func _init_threat_cache(unit: Unit) -> void:
	if unit.threat_cache_template == null:
		unit.threat_cache_template = ThreatCache.new()

	unit._threat_cache = unit.threat_cache_template.duplicate(true)
	if unit._threat_cache == null:
		unit._threat_cache = ThreatCache.new()

	unit._threat_cache.setup(unit, unit.get_unit_manager())

static func _init_behaviors(unit: Unit) -> void:
	unit.movement = UnitMovementBehavior.new(unit)
	unit.interaction = TargetInteractionHandler.new(unit)
	unit.death = UnitDeathHandler.new(unit)
	if unit.query == null:
		unit.query = UnitQueryService.new(unit)
	unit.loyalty = UnitLoyaltyComponent.new(unit)
	unit.status = UnitStatusComponent.new(unit)
	unit.visual_helper = VisualHelperComponent.new(unit)

static func _inject_dependencies(unit: Unit) -> void:
	var unit_manager : UnitManager = unit.get_unit_manager()
	if unit_manager:
		unit.set_unit_manager(unit_manager)
		if unit._movement_cache:
			unit._movement_cache.set_unit_manager(unit_manager)
		if unit._threat_cache:
			unit._threat_cache.set_unit_manager(unit_manager)

	var loot_manager : LootManager = unit.get_loot_manager()
	if loot_manager:
		unit.set_loot_manager(loot_manager)

	var task_manager : TaskManager = unit.get_task_manager()
	if task_manager:
		unit.set_task_manager(task_manager)

	var location_service : LocationService = unit.get_location_service()
	if location_service:
		unit.set_location_service(location_service)

	var combat_system : CombatSystem = unit.get_combat_system()
	if combat_system:
		unit.set_combat_system(combat_system)
