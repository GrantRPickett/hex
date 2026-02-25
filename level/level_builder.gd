class_name LevelBuilder
extends RefCounted

# location and Unit classes are auto-global in Godot 4

var _context: LevelBuildContext
var _terrain_map

func _init(context: LevelBuildContext) -> void:
	_context = context

func build(level: Level, terrain_map: TerrainMap) -> Dictionary:
	_apply_level_settings(level, terrain_map)
	_terrain_map = terrain_map
	_context.unit_manager.reset()
	if _context.loot_manager:
		_context.loot_manager.reset()
	_spawn_units(level)

	# Initialize the task_manager with the level objective
	# This triggers objective_updated signal which task_controller listens for
	if _context.task_manager and level.objective:
		print_debug("[LevelBuilder] Calling task_manager.setup() with level objective")
		# _context.task_manager.setup(_context.game_session_services, GameSessionBuilder.Config.new())

	if level.objective and not level.objective.stages.is_empty():
		_apply_stage_content(level.objective.stages[0])
	var dialogue_triggers := _spawn_level_dialogue_triggers(level)
	if _context.dialogue_service:
		_context.dialogue_service.register_triggers(dialogue_triggers)

	return {
		"grid_width": level.terrain_data.grid_width,
		"grid_height": level.terrain_data.grid_height,
	}

func _apply_level_settings(level: Level, terrain_map: TerrainMap) -> void:
	_context.camera.rotation = level.initial_rotation

	if is_instance_valid(_context.grid.tile_set):
		var ts: TileSet = _context.grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = level.hex_offset_axis
			_context.grid.tile_set = dup

	if terrain_map:
		terrain_map.set_offset_axis(level.hex_offset_axis)
		if level.terrain_data:
			terrain_map.load_from_rows(level.terrain_data.terrain_rows, level.terrain_data.grid_width, level.terrain_data.grid_height)

func _spawn_units(level: Level) -> void:
	if not _context.unit_manager:
		return

	_spawn_player_units(level)
	_spawn_enemy_units(level)
	_spawn_neutral_units(level)
	_assign_fallback_player_leader()


func _spawn_player_units(level: Level) -> void:
	if level.player_starts.is_empty() or not _context.player_roster:
		return

	var player_units_to_spawn: Array[PackedScene] = _context.player_roster.units
	for i in range(level.player_starts.size()):
		var coord = level.player_starts[i]
		if i < player_units_to_spawn.size():
			var scene_to_spawn = player_units_to_spawn[i]
			if scene_to_spawn:
				_spawn_unit(scene_to_spawn, coord, true, false, Color.WHITE)
		else:
			push_warning("[LevelBuilder] More player start positions than player units in roster. Skipping start at %s" % coord)


func _spawn_enemy_units(level: Level) -> void:
	var entries: Array = []
	if level.enemy_roster_definition and not level.enemy_roster_definition.spawn_entries.is_empty():
		entries = level.enemy_roster_definition.spawn_entries
	elif "enemy_spawns" in level and not level.enemy_spawns.is_empty():
		entries = level.enemy_spawns

	for spawn_entry in entries:
		if spawn_entry and spawn_entry.unit_scene:
			_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, false, Color.TOMATO)
		else:
			push_warning("[LevelBuilder] Invalid enemy spawn entry in level definition.")


func _spawn_neutral_units(level: Level) -> void:
	var primary_identity := _get_primary_player_identity() if _is_hometown_context() else {}
	var skip_path := String(primary_identity.get("path", ""))
	var skip_name := String(primary_identity.get("name", ""))
	var skip_coord := Vector2i(-999, -999)

	var entries: Array = []
	if level.neutral_roster_definition and not level.neutral_roster_definition.spawn_entries.is_empty():
		entries = level.neutral_roster_definition.spawn_entries
	elif "neutral_spawns" in level and not level.neutral_spawns.is_empty():
		entries = level.neutral_spawns

	for spawn_entry in entries:
		if spawn_entry == null: continue

		var scene: PackedScene = null
		var coord: Vector2i = Vector2i(-999, -999)

		if spawn_entry is Dictionary:
			scene = spawn_entry.get("unit_scene")
			coord = spawn_entry.get("coord", coord)
		elif "unit_scene" in spawn_entry:
			scene = spawn_entry.unit_scene
			if "coord" in spawn_entry:
				coord = spawn_entry.coord

		if scene == null:
			push_warning("[LevelBuilder] Invalid neutral spawn entry in level definition.")
			continue

		if _should_skip_neutral_spawn(scene, skip_path, skip_name, coord, skip_coord):
			print_debug("[LevelBuilder] Skipping hometown neutral spawn for leader scene", scene.resource_path)
			continue

		_spawn_unit(scene, coord, false, true, Color.LIGHT_SKY_BLUE)


func _spawn_hometown_player_leader(level: Level, leader_scene_path: String, leader_unit_name: String) -> Dictionary:
	var result := {"success": false, "scene_path": leader_scene_path, "unit_name": leader_unit_name, "coord": Vector2i(-999, -999)}
	if level == null:
		return result
	var info := _find_hometown_leader_entry(level, leader_scene_path, leader_unit_name)
	if info.is_empty():
		return result
	var leader_scene: PackedScene = info.get("scene")
	if leader_scene == null:
		return result
	var coord: Vector2i = info.get("coord", Vector2i(-999, -999))
	var resolved_name := leader_unit_name
	if resolved_name.is_empty():
		var instance = leader_scene.instantiate()
		if instance is Unit:
			resolved_name = instance.unit_name
		if instance is Node:
			instance.queue_free()
	print_debug("[LevelBuilder] Spawning hometown leader as player at %s" % [coord])
	_spawn_unit(leader_scene, coord, true, false, Color.WHITE)
	_ensure_leader_scene_recorded(leader_scene, leader_scene.resource_path if leader_scene.resource_path != "" else leader_scene_path, resolved_name)
	result["success"] = true
	result["scene_path"] = leader_scene.resource_path if leader_scene.resource_path != "" else leader_scene_path
	result["unit_name"] = resolved_name
	result["coord"] = coord
	return result

func _find_hometown_leader_entry(level: Level, leader_scene_path: String, leader_unit_name: String) -> Dictionary:
	var result: Dictionary = {}
	if level.neutral_roster_definition and not level.neutral_roster_definition.spawn_entries.is_empty():
		for entry in level.neutral_roster_definition.spawn_entries:
			if entry == null:
				continue
			var entry_scene: PackedScene = entry.unit_scene
			if _scene_matches_leader(entry_scene, leader_scene_path, leader_unit_name):
				result = {
					"scene": entry_scene,
					"coord": entry.coord,
				}
				return result
	elif "neutral_spawns" in level and not level.neutral_spawns.is_empty():
		for entry in level.neutral_spawns:
			if entry == null:
				continue
			var entry_scene: PackedScene = entry.get("unit_scene") if entry is Dictionary else entry.unit_scene
			var coord: Vector2i = entry.get("coord", Vector2i(-999, -999)) if entry is Dictionary else entry.coord
			if _scene_matches_leader(entry_scene, leader_scene_path, leader_unit_name):
				result = {"scene": entry_scene, "coord": coord}
				return result
	return result

func _scene_matches_leader(scene: PackedScene, leader_scene_path: String, leader_unit_name: String) -> bool:
	if scene == null:
		return false
	if not leader_scene_path.is_empty() and scene.resource_path == leader_scene_path:
		return true
	if leader_unit_name.is_empty():
		return false
	var instance = scene.instantiate()
	var matches: bool = instance is Unit and instance.unit_name == leader_unit_name
	if instance is Node:
		instance.queue_free()
	return matches

func _ensure_leader_scene_recorded(scene: PackedScene, canonical_path: String = "", leader_unit_name: String = "") -> void:
	if _context == null or _context.player_roster == null or scene == null:
		return
	for existing in _context.player_roster.units:
		if existing == scene:
			return
		if existing is PackedScene:
			var existing_path := existing.resource_path
			if canonical_path != "" and existing_path == canonical_path:
				return
			if existing_path == scene.resource_path and scene.resource_path != "":
				return
			if leader_unit_name != "" and _scene_has_unit_name(existing, leader_unit_name):
				return
	if canonical_path != "" and ResourceLoader.exists(canonical_path):
		var canonical_scene = load(canonical_path)
		if canonical_scene is PackedScene:
			_context.player_roster.units.append(canonical_scene)
			return
	_context.player_roster.units.append(scene)

func _scene_has_unit_name(scene: PackedScene, expected_name: String) -> bool:
	if scene == null or expected_name.is_empty():
		return false
	var instance = scene.instantiate()
	var matches: bool = instance is Unit and instance.unit_name == expected_name
	if instance is Node:
		instance.queue_free()
	return matches


func _log_impassable_location(coord: Vector2i) -> void:
	push_warning("[LevelBuilder] location at %s is on an impassable tile." % [coord])

func _is_location_coord_passable(coord: Vector2i) -> bool:
	if _terrain_map == null or not _terrain_map.has_method("is_passable"):
		return true
	var passable: bool = _terrain_map.is_passable(coord)
	if not passable:
		_log_impassable_location(coord)
	return passable


func _apply_stage_content(stage: Stage) -> void:
	if stage == null:
		return

	# Spawn Enemies
	for spawn_entry in stage.enemy_spawns:
		if spawn_entry and spawn_entry.unit_scene:
			_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, false, Color.TOMATO, spawn_entry.inventory)

	# Spawn Neutrals
	for spawn_entry in stage.neutral_spawns:
		if spawn_entry:
			var scene = spawn_entry.unit_scene
			if scene == null: continue

			if _should_skip_neutral_spawn(scene, "", "", spawn_entry.coord):
				continue

			_spawn_unit(scene, spawn_entry.coord, false, true, Color.LIGHT_SKY_BLUE, spawn_entry.inventory)

	# Spawn Loot
	if _context.allow_loot_spawn and _context.loot_manager:
		for loot_entry in stage.loot_spawns:
			TargetSpawner.spawn_loot(loot_entry, _context.loot_manager, _context.gameplay_root)

	# Spawn Locations
	for location_entry in stage.location_spawns:
		if not location_entry or not location_entry.location_scene:
			continue

		if not _is_location_coord_passable(location_entry.coord):
			continue

		var location_instance = TargetSpawner.spawn_location(location_entry, _context.gameplay_root, _context.grid)
		if location_instance:
			if _context.task_manager:
				_context.task_manager.register_location(location_instance)

	# Spawn Dialogue Triggers (Stage scope)
	var stage_triggers: Array[DialogueTrigger] = []
	for entry in stage.dialogue_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger: stage_triggers.append(trigger)

	for entry in stage.dialogue_journal_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger: stage_triggers.append(trigger)

	if not stage_triggers.is_empty() and _context.dialogue_service:
		_context.dialogue_service.register_triggers(stage_triggers)


	# Register Tasks
	if _context.task_manager:
		# We assume Stage logic handles task activation, but we might need to
		# ensure the TaskManager knows about the stage's tasks if they are relevant globally?
		# Actually, Stage.gd handles its own active tasks.
		# But if we want to visualize them or track them in a UI, the TaskManager might need them.
		# For now, let's assume Stage.start_stage() (called by GameState/LevelManager) will handle this.
		# This method is purely for "Placing things in the world"
		pass


func _spawn_level_dialogue_triggers(level: Level) -> Array[DialogueTrigger]:
	var triggers: Array[DialogueTrigger] = []

	# Regular dialogue entries
	for entry in level.dialogue_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger:
			triggers.append(trigger)
			_apply_trigger_group(trigger, entry)

	# Coupled dialogue/journal entries
	for entry in level.dialogue_journal_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger:
			triggers.append(trigger)
			_apply_trigger_group(trigger, entry)

	return triggers

func _apply_trigger_group(_trigger: DialogueTrigger, entry: LevelDialogueEntry) -> void:
	if not entry.group_id.is_empty():
		# This is a bit tricky as groups are usually level-wide.
		# For now, let's keep it simple.
		pass


func _is_hometown_context() -> bool:
	if _context == null:
		return false
	var hometown_path := FilePaths.DynamicPaths.get_level_path("hometown")
	return _context.level.resource_path == hometown_path or _context.level.resource_path.ends_with("/hometown.tres") or _context.level.resource_path.ends_with("\\hometown.tres")

func _get_primary_player_identity() -> Dictionary:
	var identity: Dictionary = {"path": "", "name": ""}
	if _context == null or _context.player_roster == null:
		return identity
	for scene in _context.player_roster.units:
		if scene == null:
			continue
		if identity["path"].is_empty() and scene.resource_path != "":
			identity["path"] = scene.resource_path
		if identity["name"].is_empty():
			var instance = scene.instantiate()
			if instance is Unit:
				identity["name"] = instance.unit_name
			if instance is Node:
				instance.queue_free()
		return identity
	if identity["name"].is_empty() and _context and not _context.leader_unit_name.is_empty():
		identity["name"] = _context.leader_unit_name
	return identity

func _should_skip_neutral_spawn(scene: PackedScene, leader_scene_path: String, leader_unit_name: String, entry_coord: Vector2i = Vector2i(-999, -999), hometown_coord: Vector2i = Vector2i(-999, -999)) -> bool:
	if scene == null:
		return false
	if hometown_coord != Vector2i(-999, -999) and entry_coord == hometown_coord:
		return true
	if not leader_scene_path.is_empty() and scene.resource_path == leader_scene_path:
		return true
	if leader_unit_name.is_empty():
		return false
	var instance = scene.instantiate()
	var should_skip := false
	if instance is Unit and instance.unit_name == leader_unit_name:
		should_skip = true
	if instance is Node:
		instance.queue_free()
	return should_skip

func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE, inventory: Array[InventoryItem] = []) -> void:
	var faction = Unit.Faction.ENEMY
	if is_player: faction = Unit.Faction.PLAYER
	elif is_neutral: faction = Unit.Faction.NEUTRAL

	var spawn_data := LevelUnitSpawnEntry.new()
	spawn_data.unit_scene = scene
	spawn_data.coord = coord
	spawn_data.inventory = inventory

	var unit_instance = TargetSpawner.spawn_unit(
		spawn_data,
		_context.unit_manager,
		_context.loot_manager,
		_context.task_manager,
		_context.combat_system,
		_context.grid,
		faction
	)
	if not unit_instance:
		printerr("[LevelBuilder] Error: TargetSpawner failed to spawn unit: ", scene.resource_path)
		return

	unit_instance.modulate = modulate

	# Apply additional level-specific setup that TargetSpawner doesn't handle
	_init_unit_faction(unit_instance, is_player, is_neutral)
	_apply_unit_dependencies(unit_instance)

	unit_instance.refresh_for_new_round()
	if is_player:
		unit_instance.willpower = unit_instance.max_willpower
	if unit_instance.faction == Unit.Faction.NEUTRAL and unit_instance.has_method("reset_neutral_loyalty"):
		unit_instance.reset_neutral_loyalty()

	var faction_label = "Enemy"
	if is_player: faction_label = "Player"
	elif is_neutral: faction_label = "Neutral"
	print("[LevelBuilder] Spawned %s unit '%s' at %s (Faction: %s, Scene: %s)" % [
		faction_label,
		unit_instance.unit_name,
		coord,
		unit_instance.get_faction_name(),
		scene.resource_path
	])


func _init_unit_faction(unit: Unit, is_player: bool, is_neutral: bool) -> void:
	if is_player:
		unit.faction = Unit.Faction.PLAYER
		if _context and is_instance_valid(_context.unit_manager):
			var is_leader: bool = unit.unit_name == _context.leader_unit_name
			if is_leader:
				print_debug("[LevelBuilder] Marking player leader '%s'" % unit.unit_name)
			_context.unit_manager.set_faction_leader(unit, Unit.Faction.PLAYER, is_leader)
	elif is_neutral:
		unit.faction = Unit.Faction.NEUTRAL
		if _context and is_instance_valid(_context.unit_manager):
			_context.unit_manager.set_faction_leader(unit, Unit.Faction.NEUTRAL, false)
	else:
		unit.faction = Unit.Faction.ENEMY
		if _context and is_instance_valid(_context.unit_manager):
			_context.unit_manager.set_faction_leader(unit, Unit.Faction.ENEMY, false)


func _apply_unit_dependencies(unit: Unit) -> void:
	unit.set_unit_manager(_context.unit_manager)
	unit.set_task_manager(_context.task_manager)
	unit.set_combat_system(_context.combat_system)
	if _context.loot_manager:
		unit.set_loot_manager(_context.loot_manager)
	if _context.animation_service:
		unit.set_animation_service(_context.animation_service)


func _assign_fallback_player_leader() -> void:
	if _context == null or not is_instance_valid(_context.unit_manager):
		return
	if _context.unit_manager.get_faction_leader(Unit.Faction.PLAYER) != null:
		return
	var fallback: Unit = null
	var selected_idx := _context.unit_manager.get_selected_index()
	if selected_idx >= 0:
		var candidate := _context.unit_manager.get_unit(selected_idx)
		if is_instance_valid(candidate) and candidate.faction == Unit.Faction.PLAYER:
			fallback = candidate
	if fallback == null:
		for i in range(_context.unit_manager.get_unit_count()):
			var candidate := _context.unit_manager.get_unit(i)
			if is_instance_valid(candidate) and candidate.faction == Unit.Faction.PLAYER:
				fallback = candidate
				break
	if fallback:
		_context.unit_manager.set_faction_leader(fallback, Unit.Faction.PLAYER, true)
		_context.leader_unit_name = fallback.unit_name
		print_debug("[LevelBuilder] Assigned fallback player leader '%s'" % fallback.unit_name)
