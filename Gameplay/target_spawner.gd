class_name TargetSpawner
extends RefCounted

const LOOT_SCENE_PATH := "res://Gameplay/scene_templates/loot.tscn"

## Spawns a unit based on a spawn entry resource.
## @param spawn_entry: A resource containing 'unit_scene', 'coord', and 'faction'.
## @param unit_controller: The UnitController instance to handle unit registration.
## @return: The spawned Unit instance, or null if spawning failed.
static func spawn_unit(
	spawn_entry: Variant,
	unit_manager: UnitManager,
	loot_manager: LootManager,
	task_manager: TaskManager,
	combat_system: CombatSystem,
	grid: Node2D,
	faction_override: int = -1
) -> Unit:
	if not spawn_entry or not unit_manager or not grid:
		return null

	var unit_scene = spawn_entry.get("unit_scene")
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
		unit.faction = spawn_entry.get("faction", Unit.Faction.ENEMY)
	var coord = spawn_entry.get("coord", Vector2i(-999, -999))

	unit.set_unit_manager(unit_manager)
	if loot_manager:
		unit.set_loot_manager(loot_manager)
	if task_manager:
		unit.set_task_manager(task_manager)
	if combat_system:
		unit.set_combat_system(combat_system)

	grid.add_child(unit) # Add unit to the scene tree
	unit.grid_map = grid

	# NEW LINE: Set the unit's position to the correct world coordinate before snapping.
	if coord != Vector2i(-999, -999): # Only set if a valid coord is provided
		unit.position = grid.map_to_local(coord)

	unit.snap_to_grid()
	var is_player = (unit.faction == Unit.Faction.PLAYER)
	unit_manager.add_unit(unit, coord, is_player)

	return unit

## Spawns loot based on a loot entry.
## @param loot_entry: A resource or dictionary containing 'items' and 'coord'.
## @param loot_manager: The LootManager instance.
## @param parent: The parent node to add the loot instance to.
## @return: The spawned loot node, or null if failed.
static func spawn_loot(loot_entry: Variant, loot_manager: LootManager, parent: Node = null) -> Node:
	if not loot_entry or not loot_manager:
		return null

	var items = loot_entry.get("items")
	if items == null or (items is Array and items.is_empty()):
		return null

	var coord = loot_entry.get("coord", Vector2i(-999, -999))

	var loot_scene = load(LOOT_SCENE_PATH)
	if not loot_scene:
		return null

	var loot_instance = loot_scene.instantiate()
	if loot_instance:
		if loot_instance.has_method("add_items"):
			loot_instance.add_items(items)

		if parent:
			parent.add_child(loot_instance)

		if loot_instance.has_method("is_empty") and loot_instance.is_empty():
			loot_instance.queue_free()
			return null

		loot_manager.add_loot(loot_instance, coord)

	return loot_instance

## Spawns a location based on a location entry.
## @param location_entry: A resource containing 'location_scene' and 'coord'.
## @param parent: The parent node to add the location instance to.
## @param grid: The grid node for positioning.
## @return: The spawned Location instance, or null if failed.
static func spawn_location(location_entry: Variant, parent: Node, grid: Node2D) -> Location:
	if not location_entry or not parent:
		return null

	var scene = location_entry.get("location_scene")
	if not scene:
		return null

	var coord = location_entry.get("coord", Vector2i(-999, -999))
	var location_instance = scene.instantiate()
	if location_instance is Location:
		parent.add_child(location_instance)
		if grid and grid.has_method("map_to_local"):
			if "grid_map" in location_instance:
				location_instance.grid_map = grid
			location_instance.position = grid.map_to_local(coord)
		if location_instance.has_method("set_grid_coord"):
			location_instance.set_grid_coord(coord)
		return location_instance

	location_instance.queue_free()
	return null

static func spawn_or_update_location(location_entry: Variant, parent: Node, grid: Node2D) -> Location:
	var coord = location_entry.get("coord", Vector2i(-999, -999))
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