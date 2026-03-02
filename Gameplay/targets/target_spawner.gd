class_name TargetSpawner
extends RefCounted

## Spawns a unit based on a spawn entry resource.
## @param spawn_entry: A LevelUnitSpawnEntry resource.
## @param unit_manager: The UnitController instance to handle unit registration.
## @return: The spawned Unit instance, or null if spawning failed.
static func spawn_unit(
	spawn_entry: LevelUnitSpawnEntry,
	unit_manager: UnitManager,
	loot_manager: LootManager,
	task_manager: TaskManager,
	combat_system: CombatSystem,
	grid: Node2D,
	faction_override: int = -1
) -> Unit:
	if not spawn_entry or not unit_manager or not grid:
		return null

	var unit_scene = spawn_entry.get_unit_scene()
	if not unit_scene:
		return null

	var unit_instance = unit_scene.instantiate()
	if not (unit_instance is Unit):
		unit_instance.queue_free()
		return null

	var unit = unit_instance as Unit
	if faction_override != -1:
		unit.faction = faction_override
	else:
		unit.faction = Unit.Faction.ENEMY # Default to ENEMY

	var coord = spawn_entry.get_coord()

	unit.set_unit_manager(unit_manager)
	if loot_manager:
		unit.set_loot_manager(loot_manager)
	if task_manager:
		unit.set_task_manager(task_manager)
	if combat_system:
		unit.set_combat_system(combat_system)

	# Handle Inventory
	var inventory_data = spawn_entry.get_inventory()
	if not inventory_data.is_empty():
		for item in inventory_data:
			if item is InventoryItem:
				unit.saved_items.append(item)

	grid.add_child(unit) # Add unit to the scene tree
	unit.grid_map = grid


	# NEW LINE: Set the unit's position to the correct world coordinate before snapping.
	if coord != Vector2i(-999, -999): # Only set if a valid coord is provided
		unit.position = grid.map_to_local(coord)

	var ai_profile = spawn_entry.get_ai_profile()
	if ai_profile:
		unit.combat_priority_profile = ai_profile

	_apply_attributes(unit, spawn_entry)

	unit.snap_to_grid()
	var is_player = (unit.faction == Unit.Faction.PLAYER)
	unit_manager.add_unit(unit, coord, is_player)

	return unit

static func _apply_attributes(target: Target, entry: Resource) -> void:
	if not target or not entry:
		return
	
	if "grit" in entry: target.grit = entry.grit
	if "flow" in entry: target.flow = entry.flow
	if "gusto" in entry: target.gusto = entry.gusto
	if "focus" in entry: target.focus = entry.focus
	if "shine" in entry: target.shine = entry.shine
	if "shade" in entry: target.shade = entry.shade
	
	if "willpower" in entry:
		if target is Unit:
			target.willpower = entry.willpower
		else:
			target.base_willpower = entry.willpower

## Spawns loot based on a loot entry.
## @param loot_entry: A LevelLootEntry resource.
## @param loot_manager: The LootManager instance.
## @param parent: The parent node to add the loot instance to.
## @return: The spawned loot node, or null if failed.
static func spawn_loot(loot_entry: LevelLootEntry, loot_manager: LootManager, parent: Node = null) -> Node:
	if not loot_entry or not loot_manager:
		return null

	var items = loot_entry.get_items()
	if items.is_empty():
		return null

	var coord = loot_entry.get_coord()

	var loot_scene = load(FilePaths.Scenes.LOOT)

	var loot_instance = loot_scene.instantiate()
	if loot_instance:
		if loot_instance is Loot:
			var loot := loot_instance as Loot
			if loot.has_method("add_items"):
				loot.add_items(items)
			
			if "is_trapped" in loot_entry:
				loot.is_trapped = loot_entry.is_trapped
			
			_apply_attributes(loot, loot_entry)

		if parent:
			parent.add_child(loot_instance)

		if loot_instance.has_method("is_empty") and loot_instance.is_empty():
			loot_instance.queue_free()
			return null

		loot_manager.add_loot(loot_instance, coord)

	return loot_instance

## Spawns a location based on a location entry.
## @param location_entry: A LevelTaskEntry resource.
## @param parent: The parent node to add the location instance to.
## @param grid: The grid node for positioning.
## @return: The spawned Location instance, or null if failed.
static func spawn_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location:
	if not location_entry or not parent:
		return null

	var scene = location_entry.get_location_scene()
	if not scene:
		return null

	var coord = location_entry.get_coord()
	var location_instance = scene.instantiate()
	if location_instance is Location:
		var location := location_instance as Location
		parent.add_child(location)
		
		_apply_attributes(location, location_entry)
		
		if grid and grid.has_method("map_to_local"):
			if "grid_map" in location_instance:
				location_instance.grid_map = grid
			location_instance.position = grid.map_to_local(coord)
		if location_instance.has_method("set_grid_coord"):
			location_instance.set_grid_coord(coord)
		return location_instance

	location_instance.queue_free()
	return null

static func spawn_or_update_location(location_entry: LevelTaskEntry, parent: Node, grid: Node2D) -> Location:
	var coord = location_entry.get_coord()
	if parent:
		for child in parent.get_children():
			if child is Location:
				var loc_coord = child.coord if "coord" in child else Vector2i(-999, -999)
				if loc_coord == coord:
					child.position = grid.map_to_local(coord) if grid and grid.has_method("map_to_local") else child.position
					 # Update grid_map reference if needed
					if "grid_map" in child:
						child.grid_map = grid
					child.set_grid_coord(coord)
					return child
	return spawn_location(location_entry, parent, grid)

## Spawns a dialogue trigger based on a dialogue entry resource.
## @param dialogue_entry: A LevelDialogueEntry resource.
## @param parent: The parent node to add the trigger to.
## @param grid: The grid node for positioning.
## @return: The spawned DialogueTrigger instance, or null if failed.
static func spawn_dialogue_trigger(dialogue_entry: LevelDialogueEntry, parent: Node, grid: TileMapLayer) -> DialogueTrigger:
	if not dialogue_entry or not parent:
		return null

	var trigger := DialogueTrigger.new()
	trigger.configure_from_entry(dialogue_entry)

	parent.add_child(trigger)
	trigger.assign_coord_on_grid(grid)

	return trigger
