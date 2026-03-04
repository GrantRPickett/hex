class_name TargetSpawner
extends RefCounted

const LOOT_SCENE = preload("res://Gameplay/scene_templates/loot.tscn")

## Spawns a unit based on a spawn entry resource.
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
		push_error("[TargetSpawner] Missing unit_scene in spawn_entry")
		return null

	var unit_instance = unit_scene.instantiate()
	if not (unit_instance is Unit):
		push_error("[TargetSpawner] Instantiated scene is not a Unit: %s" % unit_scene.resource_path)
		unit_instance.queue_free()
		return null

	var unit = unit_instance as Unit

	# Faction resolution: Override > Entry > Default (ENEMY)
	if faction_override != -1:
		unit.faction = faction_override as Unit.Faction
	elif spawn_entry.faction != -1:
		unit.faction = spawn_entry.faction as Unit.Faction
	else:
		unit.faction = Unit.Faction.ENEMY

	# Dependency injection
	unit.set_unit_manager(unit_manager)
	if loot_manager:
		unit.set_loot_manager(loot_manager)
	if task_manager:
		unit.set_task_manager(task_manager)
	if combat_system:
		unit.set_combat_system(combat_system)

	# Handle Inventory
	for item in spawn_entry.inventory:
		if is_instance_valid(item):
			unit.saved_items.append(item)

	grid.add_child(unit)
	unit.grid_map = grid

	var coord = spawn_entry.get_coord()
	if coord != Vector2i(-999, -999):
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

		# Willpower is special on Units (managed by ActionPointsComponent)
		if target is Unit:
			target.willpower = entry_stats.willpower
		else:
			target.base_willpower = entry_stats.willpower
	else:
		# Fallback to direct properties on entry
		for attr in Target.COMBAT_ATTRIBUTE_NAMES:
			if attr in entry:
				target.set(attr, entry.get(attr))

		if "willpower" in entry:
			if target is Unit:
				target.willpower = entry.willpower
			else:
				target.base_willpower = entry.willpower


## Spawns loot based on a loot entry.
static func spawn_loot(loot_entry: LevelLootEntry, loot_manager: LootManager, parent: Node = null, grid: Node2D = null) -> Node:
	if not loot_entry or not loot_manager:
		return null

	var items = loot_entry.get_items()
	if items.is_empty():
		return null

	var loot_instance = LOOT_SCENE.instantiate()
	if not (loot_instance is Loot):
		loot_instance.queue_free()
		return null

	var loot := loot_instance as Loot
	loot.add_items(items)

	if "is_trapped" in loot_entry:
		loot.is_trapped = loot_entry.is_trapped

	_apply_attributes(loot, loot_entry)

	if parent:
		parent.add_child(loot)

	if loot.is_empty():
		loot.queue_free()
		return null

	var coord = loot_entry.get_coord()
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

	var location_instance = scene.instantiate()
	if not (location_instance is Location):
		location_instance.queue_free()
		return null

	var location := location_instance as Location
	parent.add_child(location)

	if not location_entry.location_name.is_empty():
		location.loc_name = location_entry.location_name

	if not location_entry.description.is_empty():
		location.description = location_entry.description

	_apply_attributes(location, location_entry)

	var coord = location_entry.get_coord()
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

	var coord = location_entry.get_coord()
	if parent:
		for child in parent.get_children():
			if child is Location:
				var loc_coord = child.coord if "coord" in child else Vector2i(-999, -999)
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
