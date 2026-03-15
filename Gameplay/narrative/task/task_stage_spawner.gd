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
		return false

	var grid: TileMapLayer = _state.map_controller.get_grid()
	var spawn_occurred := false

	spawn_occurred = _spawn_stage_units(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_loot(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_locations(stage, grid) or spawn_occurred
	spawn_occurred = _spawn_stage_dialogue_triggers(stage, grid) or spawn_occurred

	return spawn_occurred

func _spawn_stage_units(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	for field in ["enemy_spawns", "neutral_spawns", "spawns"]:
		var spawns = stage.get(field)
		if spawns.is_empty(): continue

		var faction_override: int = -1
		if field == "enemy_spawns":
			faction_override = Unit.Faction.ENEMY
		elif field == "neutral_spawns":
			faction_override = Unit.Faction.NEUTRAL

		for spawn in spawns:
			if not spawn or not (spawn is LevelUnitSpawnEntry): continue

			if spawn.unit_scene == null:
				print_debug("[Task] Skipping unit spawn at %s: unit_scene is null" % spawn.coord)
				continue
			if _unit_manager.get_unit_at_coord(spawn.coord) != null:
				print_debug("[Task] Skipping unit spawn at %s: already occupied" % spawn.coord)
				continue

			var unit: Unit = TargetSpawner.spawn_unit(spawn, _unit_manager, _loot_manager, _task_manager, _location_service, _combat_system, grid, faction_override)
			if unit:
				spawned = true
				print_debug("[Task] Spawned stage-specific unit: ", unit.unit_name, " at ", spawn.coord)
	return spawned

func _spawn_stage_loot(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var loot_spawns  = stage.get("loot_spawns") if stage.has_method("get") else []
	for loot_entry in loot_spawns:
		if not loot_entry: continue
		if _loot_manager and _loot_manager.has_loot_at(loot_entry.get_coord()):
			print_debug("[Task] Skipping loot spawn at %s: already exists" % loot_entry.get_coord())
			continue
		var loot_instance: Node = TargetSpawner.spawn_loot(loot_entry, _loot_manager, _state.grid, grid)
		if loot_instance and _task_manager:
			_task_manager.register_loot(loot_instance)
			spawned = true
			print_debug("[Task] Spawned stage-specific loot at ", loot_entry.get_coord())
	return spawned

func _spawn_stage_locations(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var location_spawns = stage.get("location_spawns") if stage.has_method("get") else []
	for location_entry in location_spawns:
		if not location_entry: continue
		var existing_loc:  = _task_manager.get_location_at(location_entry.get_coord()) if _task_manager else null
		if existing_loc:
			print_debug("[Task] Skipping location spawn at %s: already exists" % location_entry.get_coord())
			continue
		var location_instance: Node = TargetSpawner.spawn_location(location_entry, _state.grid, grid)
		if location_instance and _task_manager:
			_task_manager.register_location(location_instance)
			spawned = true
			print_debug("[Task] Spawned stage-specific location: ", location_instance.loc_name, " at ", location_entry.get_coord())
	return spawned

func _spawn_stage_dialogue_triggers(stage: Resource, grid: TileMapLayer) -> bool:
	var spawned := false
	var dialogue_entries  = stage.get("dialogue_entries") if stage.has_method("get") else []
	for entry in dialogue_entries:
		if not entry: continue
		var trigger: DialogueTrigger = TargetSpawner.spawn_dialogue_trigger(entry, _state.grid, grid)
		if trigger:
			spawned = true
			print_debug("[Task] Spawned stage-specific dialogue trigger at ", entry.coord)
	return spawned
