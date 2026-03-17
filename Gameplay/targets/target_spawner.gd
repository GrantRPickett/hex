class_name TargetSpawner
extends RefCounted

const LOOT_SCENE = preload(FilePaths.Scenes.LOOT)

## Spawns a unit based on a spawn entry resource.
static func spawn_unit(
	spawn_entry: LevelUnitSpawnEntry,
	unit_manager: UnitManager,
	loot_manager: LootManager,
	task_manager: TaskManager,
	location_service: LocationService,
	combat_system: CombatSystem,
	grid: Node2D,
	faction_override: int = -1
) -> Unit:
	if not spawn_entry or not unit_manager or not grid:
		return null

	var unit_scene = spawn_entry.get_unit_scene()
	if not unit_scene:
		push_error("[TargetSpawner] Missing unit_scene in spawn_entry")
		return null

	var unit_instance: Node = unit_scene.instantiate()
	if not (unit_instance is Unit):
		push_error("[TargetSpawner] Instantiated scene is not a Unit: %s" % unit_scene.resource_path)
		unit_instance.queue_free()
		return null

	var unit: Unit = unit_instance as Unit
	
	_set_unit_identity(unit, spawn_entry, unit_scene, faction_override)
	_inject_unit_dependencies(unit, unit_manager, loot_manager, task_manager, location_service, combat_system)

	# Handle Inventory
	for item in spawn_entry.inventory:
		if is_instance_valid(item):
			if item is InventoryItem:
				unit.saved_items.append(item.duplicate_instance(true))
			else:
				unit.saved_items.append(item.duplicate(true))

	grid.add_child(unit)
	if grid is TileMapLayer:
		unit.grid_map = grid

	var coord: Vector2i = spawn_entry.get_coord()
	if coord != GameConstants.INVALID_COORD:
		unit.position = grid.map_to_local(coord)

	var ai_profile = spawn_entry.get_ai_profile()
	if ai_profile:
		unit.combat_priority_profile = ai_profile

	_apply_attributes(unit, spawn_entry)

	unit.snap_to_grid()
	var is_player = (unit.faction == GameConstants.Faction.PLAYER)
	unit_manager.add_unit(unit, coord, is_player)

	return unit


static func _set_unit_identity(unit: Unit, entry: LevelUnitSpawnEntry, scene: PackedScene, faction_override: int) -> void:
	if "id" in entry and not entry.id.is_empty():
		unit.id = entry.id

	# Faction resolution: Override > Entry > Default (ENEMY)
	if faction_override != -1:
		unit.faction = faction_override as GameConstants.Faction
	elif entry.faction != -1:
		unit.faction = entry.faction as GameConstants.Faction
	else:
		unit.faction = GameConstants.Faction.ENEMY

	if "loyalty_type" in entry:
		unit.loyalty_type = entry.loyalty_type
	if "neutral_can_be_persuaded" in entry:
		unit.neutral_can_be_persuaded = entry.neutral_can_be_persuaded

	if not entry.unit_name.is_empty():
		unit.unit_name = entry.unit_name
	elif unit.unit_name == "Unit" or unit.unit_name.is_empty():
		var fallback_name = scene.resource_path.get_file().get_basename().capitalize()
		unit.unit_name = fallback_name


static func _inject_unit_dependencies(
	unit: Unit,
	unit_manager: UnitManager,
	loot_manager: LootManager,
	task_manager: TaskManager,
	location_service: LocationService,
	combat_system: CombatSystem
) -> void:
	unit.set_unit_manager(unit_manager)
	if loot_manager:
		unit.set_loot_manager(loot_manager)
	if task_manager:
		unit.set_task_manager(task_manager)
	if location_service:
		unit.set_location_service(location_service)
	if combat_system:
		unit.set_combat_system(combat_system)


static func _apply_attributes(target: Target, entry: Resource) -> void:
	if not target or not entry:
		return

	var entry_stats: CombatStats = null
	if entry.has_method("get_stats"):
		entry_stats = entry.get_stats()
	elif "stats" in entry:
		entry_stats = entry.stats as CombatStats

	if entry_stats:
		target.grit = entry_stats.grit
		target.flow = entry_stats.flow
		target.gusto = entry_stats.gusto
		target.focus = entry_stats.focus
		target.shine = entry_stats.shine
		target.shade = entry_stats.shade
		target.base_willpower = entry_stats.willpower

		# Current willpower is special on Units (managed by ActionPointsComponent)
		if target is Unit:
			target.willpower = entry_stats.willpower
			target.movement_points = entry_stats.movement_points
	else:
		# Fallback to direct properties on entry
		for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
			var attr_name := GameConstants.get_attribute_name(attr_idx)
			if attr_name in entry:
				target.set(attr_name, entry.get(attr_name))

		if "willpower" in entry:
			if target is Unit:
				target.willpower = entry.willpower
			else:
				target.base_willpower = entry.willpower


## Spawns loot based on a loot entry.
static func spawn_loot(loot_entry: LevelLootEntry, loot_manager: LootManager, parent: Node = null, grid: Node2D = null) -> Node:
	if not loot_entry or not loot_manager:
		return null

	var items: Array = loot_entry.get_items()
	if items.is_empty() and (not "id" in loot_entry or loot_entry.id.is_empty()):
		return null

	var loot_instance: Node = LOOT_SCENE.instantiate()
	if not (loot_instance is Loot):
		loot_instance.queue_free()
		return null

	var loot := loot_instance as Loot
	loot.add_items(items)

	if "id" in loot_entry and not loot_entry.id.is_empty():
		loot.id = loot_entry.id
		loot.loot_name = loot_entry.id

	if "is_trapped" in loot_entry:
		loot.is_trapped = loot_entry.is_trapped

	_apply_attributes(loot, loot_entry)

	if parent:
		parent.add_child(loot)

	if loot.is_empty() and (not "id" in loot_entry or loot_entry.id.is_empty()):
		loot.queue_free()
		return null

	var coord: Vector2i = loot_entry.get_coord()
	if grid and grid.has_method("map_to_local"):
		loot.position = grid.map_to_local(coord)

	loot_manager.add_loot(loot, coord)
	return loot


## Spawns a location based on a location entry.
static func spawn_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location:
	if not location_entry or not parent:
		return null

	var scene = location_entry.get_location_scene()
	if not scene:
		return null

	var location_instance: Node = scene.instantiate()
	if not (location_instance is Location):
		location_instance.queue_free()
		return null

	var location := location_instance as Location
	parent.add_child(location)

	if "id" in location_entry and not location_entry.id.is_empty():
		location.id = location_entry.id

	if not location_entry.location_name.is_empty():
		location.loc_name = location_entry.location_name

	if not location_entry.description.is_empty():
		location.description = location_entry.description

	if "loyalty" in location_entry:
		location.loyalty = location_entry.loyalty


	_apply_attributes(location, location_entry)

	var coord: Vector2i = location_entry.get_coord()
	if grid:
		if "grid_map" in location:
			location.grid_map = grid
		if grid.has_method("map_to_local"):
			location.position = grid.map_to_local(coord)

	if location.has_method("set_grid_coord"):
		location.set_grid_coord(coord)

	return location


static func spawn_or_update_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location:
	if not location_entry:
		return null

	var coord: Vector2i = location_entry.get_coord()
	if parent:
		for child in parent.get_children():
			if child is Location:
				var loc_coord: Vector2i = child.coord if "coord" in child else Vector2i(-999, -999)
				if loc_coord == coord:
					if grid and grid.has_method("map_to_local"):
						child.position = grid.map_to_local(coord)
					if "grid_map" in child:
						child.grid_map = grid
					if child.has_method("set_grid_coord"):
						child.set_grid_coord(coord)
					return child

	return spawn_location(location_entry, parent, grid)


## Spawns a dialogue trigger based on a dialogue entry resource.
static func spawn_dialogue_trigger(dialogue_entry: LevelDialogueEntry, parent: Node, grid: TileMapLayer) -> DialogueTrigger:
	if not dialogue_entry or not parent:
		return null

	var trigger := DialogueTrigger.new()
	trigger.configure_from_entry(dialogue_entry)

	parent.add_child(trigger)
	trigger.assign_coord_on_grid(grid)

	return trigger
