class_name TaskStageSpawner
extends RefCounted

var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _location_service: LocationService
var _combat_system: CombatSystem
var _state: GameState

func _init(state: GameState) -> void:
	_state = state
	_unit_manager = state.unit_manager
	_loot_manager = state.loot_manager
	_task_manager = state.task_manager
	_location_service = state.location_service
	_combat_system = state.combat_system

func handle_stage_spawns(stage: Resource) -> bool:
	if not _unit_manager or not _state.map_controller:
		GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Missing unit_manager or map_controller")
		return false

	var grid: TileMapLayer = _state.map_controller.get_grid()
	if not is_instance_valid(grid):
		GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Grid is invalid")
		return false

	var spawn_occurred := false
	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Handling spawns for stage: ", stage.id if "id" in stage else "unknown")

	spawn_occurred = _spawn_stage_units(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_loot(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_locations(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_dialogue_triggers(stage, grid) or spawn_occurred

	return spawn_occurred

func _spawn_stage_units(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	for field in ["enemy_spawns", "neutral_spawns", "spawns"]:
		var spawns = stage.get(field)
		if not spawns or spawns.is_empty(): continue

		GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Found %d entries in %s" % [spawns.size(), field])

		var faction_override: int = -1
		if field == "enemy_spawns":
			faction_override = GameConstants.Faction.ENEMY
		elif field == "neutral_spawns":
			faction_override = GameConstants.Faction.NEUTRAL

		for spawn in spawns:
			if not spawn: continue

			# More robust type check using script path comparison if 'is' fails
			var is_spawn_entry = spawn is LevelUnitSpawnEntry
			if not is_spawn_entry and spawn.has_method("get_script"):
				var s = spawn.get_script()
				if s and s.resource_path.find("level_unit_spawn_entry.gd") != -1:
					is_spawn_entry = true

			if not is_spawn_entry:
				GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Entry in %s is not a LevelUnitSpawnEntry" % field)
				continue

			if spawn.unit_scene == null:
				GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Skipping unit spawn at %s: unit_scene is null" % spawn.coord)
				continue

			var existing_unit = _unit_manager.get_unit_at_coord(spawn.coord)
			if existing_unit != null:
				GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Unit at %s already exists, re-registering." % spawn.coord)
				if _task_manager:
					_task_manager.register_unit(existing_unit)
				continue

			var unit: Unit = TargetSpawner.spawn_unit(spawn, _unit_manager, _loot_manager, _task_manager, _location_service, _combat_system, grid, faction_override)
			if unit:
				spawned = true
				GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Spawned stage-specific unit: ", unit.unit_name, " at ", spawn.coord)
			else:
				GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] TargetSpawner failed to spawn unit at ", spawn.coord)
	return spawned

func _spawn_stage_loot(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var loot_spawns = stage.get("loot_spawns") if "loot_spawns" in stage else []
	if not loot_spawns or loot_spawns.is_empty(): return false

	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Found %d loot spawns" % loot_spawns.size())

	for loot_entry in loot_spawns:
		if not loot_entry: continue

		# Robust type check
		var is_loot_entry = loot_entry is LevelLootEntry
		if not is_loot_entry and loot_entry.has_method("get_script"):
			var s = loot_entry.get_script()
			if s and s.resource_path.find("level_loot_entry.gd") != -1:
				is_loot_entry = true

		if not is_loot_entry:
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Entry is not a LevelLootEntry")
			continue

		if _loot_manager and _loot_manager.has_loot_at(loot_entry.get_coord()):
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Loot at %s already exists, re-registering." % loot_entry.get_coord())
			if _task_manager:
				var existing_loot = _loot_manager.get_loot_at(loot_entry.get_coord())
				if existing_loot:
					_task_manager.register_loot(existing_loot)
			continue

		var loot_instance: Node = TargetSpawner.spawn_loot(loot_entry, _loot_manager, _state.grid, grid)
		if loot_instance and _task_manager:
			_task_manager.register_loot(loot_instance)
			spawned = true
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Spawned stage-specific loot at ", loot_entry.get_coord())
	return spawned

func _spawn_stage_locations(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var entries_to_spawn: Array[LevelLocationEntry] = []

	# Collect entries from explicit location_spawns
	var stage_location_spawns = stage.get("location_spawns") if "location_spawns" in stage else []
	for entry in stage_location_spawns:
		if entry is LevelLocationEntry:
			entries_to_spawn.append(entry)

	# Collect entries from tasks (the "task makes target" pattern)
	var stage_tasks = stage.get("tasks") if "tasks" in stage else []
	for task in stage_tasks:
		if task is Task and task.target_spawn != null and task.target_spawn is LevelLocationEntry:
			entries_to_spawn.append(task.target_spawn)

	if entries_to_spawn.is_empty():
		return false

	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Found %d location entries" % entries_to_spawn.size())

	# Deduplicate by coordinate to avoid double spawns across task/location listings
	var unique_entries: Array[LevelLocationEntry] = []
	var seen_coords: Dictionary = {}
	for entry in entries_to_spawn:
		if seen_coords.has(entry.coord):
			continue
		seen_coords[entry.coord] = true
		unique_entries.append(entry)

	for location_entry in unique_entries:
		var coord: Vector2i = location_entry.coord

		if _task_manager and _task_manager.get_location_at(coord) != null:
			var existing = _task_manager.get_location_at(coord)
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Location at %s already exists (%s), skipping spawn but ensuring registration." % [coord, existing.name])
			_task_manager.register_location(existing)
			continue

		var location_instance: Node = TargetSpawner.spawn_location(location_entry, _state.grid, grid)
		if location_instance and _task_manager:
			_task_manager.register_location(location_instance)
			spawned = true
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Spawned location: %s at %s" % [location_entry.location_name, coord])

	return spawned

func _spawn_stage_dialogue_triggers(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var dialogue_entries = stage.get("dialogue_entries") if "dialogue_entries" in stage else []
	var dialogue_journal_entries = stage.get("dialogue_journal_entries") if "dialogue_journal_entries" in stage else []

	var all_entries = []
	if dialogue_entries: all_entries.append_array(dialogue_entries)
	if dialogue_journal_entries: all_entries.append_array(dialogue_journal_entries)

	if all_entries.is_empty(): return false

	GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Found %d dialogue entries" % all_entries.size())

	for entry in all_entries:
		if not entry: continue
		if entry.coord == GameConstants.INVALID_COORD:
			continue

		var trigger: DialogueTrigger = TargetSpawner.spawn_dialogue_trigger(entry, _state.grid, grid)
		if trigger:
			spawned = true
			GameLogger.debug(GameLogger.Category.SYSTEM, "[TaskStageSpawner] Spawned stage-specific dialogue trigger at ", entry.coord)
	return spawned
