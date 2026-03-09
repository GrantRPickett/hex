class_name LevelContentSpawner
extends RefCounted

var _context: LevelBuildContext
var _terrain_map

func _init(context: LevelBuildContext, terrain_map) -> void:
	_context = context
	_terrain_map = terrain_map

func spawn_global_content(level: Level) -> void:
	if _context == null: return

	_context.unit_manager.begin_batch_placement()

	var already_spawned_leader_path := ""
	if _is_hometown_context():
		var leader_scene_path := String(_context.player_roster.units[0].resource_path) if not _context.player_roster.units.is_empty() else ""
		var result = _spawn_hometown_player_leader(level, leader_scene_path, _context.leader_unit_name)
		if result.get("success", false):
			already_spawned_leader_path = result.get("scene_path", "")

	_spawn_player_units(level, already_spawned_leader_path)
	_spawn_enemy_units(level)
	_spawn_neutral_units(level)
	_assign_fallback_player_leader()

	var dialogue_triggers := _spawn_level_dialogue_triggers(level)
	if _context.dialogue_service:
		_context.dialogue_service.register_triggers(dialogue_triggers)

	_context.unit_manager.end_batch_placement()

func _spawn_player_units(level: Level, skip_scene_path: String = "") -> void:
	if level.player_spawns.is_empty():
		if not level.player_starts.is_empty() and _context.player_roster:
			_spawn_roster_units_at_coords(level.player_starts, skip_scene_path)
		return

	for i in range(level.player_spawns.size()):
		var entry = level.player_spawns[i]
		if entry == null: continue

		var coord = entry.coord
		if _terrain_map and not _is_location_coord_passable(coord):
			continue

		# If an explicit unit scene is provided, use it (scripted unit)
		if entry.unit_scene:
			if not skip_scene_path.is_empty() and entry.unit_scene.resource_path == skip_scene_path:
				continue
			_spawn_unit(entry.unit_scene, coord, true, false, Color.WHITE, entry.inventory)
			print_debug("[LevelContentSpawner] Spawned scripted player unit at ", coord)
			continue

		# Otherwise fallback to roster by slot index
		if _context.player_roster and entry.slot_index < _context.player_roster.units.size():
			var roster_scene = _context.player_roster.units[entry.slot_index]
			if roster_scene:
				if not skip_scene_path.is_empty() and roster_scene.resource_path == skip_scene_path:
					continue
				_spawn_unit(roster_scene, coord, true, false, Color.WHITE)
				print_debug("[LevelContentSpawner] Spawned roster player unit at ", coord)

func _spawn_roster_units_at_coords(coords: Array[Vector2i], skip_scene_path: String) -> void:
	var player_units_to_spawn: Array[PackedScene] = _context.player_roster.units
	for i in range(coords.size()):
		var coord = coords[i]
		if i < player_units_to_spawn.size():
			var scene_to_spawn = player_units_to_spawn[i]
			if scene_to_spawn == null: continue
			if not skip_scene_path.is_empty() and scene_to_spawn.resource_path == skip_scene_path:
				continue
			_spawn_unit(scene_to_spawn, coord, true, false, Color.WHITE)

func _spawn_enemy_units(level: Level) -> void:
	var entries := []
	if level.enemy_roster_definition and not level.enemy_roster_definition.spawn_entries.is_empty():
		entries = level.enemy_roster_definition.spawn_entries
	elif not level.enemy_spawns.is_empty():
		entries = level.enemy_spawns

	for raw in entries:
		if raw == null: continue
		var parsed := SpawnUtils.parse_entry(raw)
		var scene: PackedScene = parsed.scene
		var coord: Vector2i = parsed.coord
		if scene == null: continue
		if _terrain_map and not _is_location_coord_passable(coord):
			continue
		_spawn_unit(scene, coord, false, false, Color.TOMATO)
		print_debug("[LevelContentSpawner] Spawned global enemy unit at ", coord)

func _spawn_neutral_units(level: Level) -> void:
	var primary_identity := _get_primary_player_identity() if _is_hometown_context() else {"path": "", "name": ""}
	var skip_path := String(primary_identity.get("path", ""))
	var skip_name := String(primary_identity.get("name", ""))

	var entries := []
	if level.neutral_roster_definition and not level.neutral_roster_definition.spawn_entries.is_empty():
		entries = level.neutral_roster_definition.spawn_entries
	elif not level.neutral_spawns.is_empty():
		entries = level.neutral_spawns

	for raw in entries:
		if raw == null: continue
		var parsed := SpawnUtils.parse_entry(raw)
		var scene: PackedScene = parsed.scene
		var coord: Vector2i = parsed.coord
		if scene == null: continue
		if _should_skip_neutral_spawn(scene, skip_path, skip_name, coord):
			continue
		if _terrain_map and not _is_location_coord_passable(coord):
			continue
		_spawn_unit(scene, coord, false, true, Color.LIGHT_SKY_BLUE)
		print_debug("[LevelContentSpawner] Spawned global neutral unit at ", coord)

func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE, inventory: Array[InventoryItem] = []) -> void:
	var faction = Unit.Faction.ENEMY
	if is_player: faction = Unit.Faction.PLAYER
	elif is_neutral: faction = Unit.Faction.NEUTRAL

	var spawn_data := LevelUnitSpawnEntry.new()
	spawn_data.unit_scene = scene
	spawn_data.coord = coord
	spawn_data.inventory = inventory

	var unit_instance = TargetSpawner.spawn_unit(
		spawn_data, _context.unit_manager, _context.loot_manager, _context.task_manager,
		_context.location_service, _context.combat_system, _context.grid, faction
	)
	if not unit_instance:
		printerr("[LevelContentSpawner] Error: TargetSpawner failed to spawn unit: ", scene.resource_path)
		return

	_verify_unit_components(unit_instance)

	unit_instance.modulate = modulate
	_init_unit_faction(unit_instance, is_player, is_neutral)
	_apply_unit_dependencies(unit_instance)
	unit_instance.refresh_for_new_round()
	if is_player: unit_instance.willpower = unit_instance.max_willpower
	if unit_instance.faction == Unit.Faction.NEUTRAL and unit_instance.loyalty:
		unit_instance.loyalty.reset_neutral_loyalty()

func _verify_unit_components(unit: Unit) -> void:
	if unit.combat_priority_profile == null:
		push_warning("[LevelContentSpawner] Verification: Unit '%s' is missing a CombatPriorityProfile." % unit.unit_name)
	if unit.action_points_template == null:
		push_warning("[LevelContentSpawner] Verification: Unit '%s' is missing an ActionPointsComponent template." % unit.unit_name)
	if unit.inventory_component_template == null:
		push_warning("[LevelContentSpawner] Verification: Unit '%s' is missing an InventoryComponent template." % unit.unit_name)


func _init_unit_faction(unit: Unit, is_player: bool, is_neutral: bool) -> void:
	if is_player:
		unit.faction = Unit.Faction.PLAYER
		if _context and is_instance_valid(_context.unit_manager):
			if unit.unit_name == _context.leader_unit_name:
				_context.unit_manager.set_faction_leader(unit, Unit.Faction.PLAYER)
	elif is_neutral:
		unit.faction = Unit.Faction.NEUTRAL
	else:
		unit.faction = Unit.Faction.ENEMY

func _apply_unit_dependencies(unit: Unit) -> void:
	unit.set_unit_manager(_context.unit_manager)
	unit.set_task_manager(_context.task_manager)
	unit.set_location_service(_context.location_service)
	unit.set_combat_system(_context.combat_system)
	if _context.loot_manager: unit.set_loot_manager(_context.loot_manager)
	if _context.animation_service: unit.set_animation_service(_context.animation_service)

func _assign_fallback_player_leader() -> void:
	if _context == null or not is_instance_valid(_context.unit_manager): return
	if _context.unit_manager.get_faction_leader(Unit.Faction.PLAYER) != null: return
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
		_context.unit_manager.set_faction_leader(fallback, Unit.Faction.PLAYER)
		_context.leader_unit_name = fallback.unit_name

func _spawn_level_dialogue_triggers(level: Level) -> Array[DialogueTrigger]:
	var triggers: Array[DialogueTrigger] = []
	for entry in level.dialogue_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger:
			triggers.append(trigger)
			_apply_trigger_group(trigger, entry)
	for entry in level.dialogue_journal_entries:
		var trigger := TargetSpawner.spawn_dialogue_trigger(entry, _context.gameplay_root, _context.grid)
		if trigger:
			triggers.append(trigger)
			_apply_trigger_group(trigger, entry)
	return triggers

func _apply_trigger_group(_trigger: DialogueTrigger, entry: LevelDialogueEntry) -> void:
	if not entry.group_id.is_empty():
		pass # Implement group logic if needed

func _is_location_coord_passable(coord: Vector2i) -> bool:
	if _terrain_map == null or not _terrain_map.has_method("is_passable"): return true
	return _terrain_map.is_passable(coord)

func _is_hometown_context() -> bool:
	return _context != null and _context.level != null and _is_hometown_level(_context.level)

func _is_hometown_level(level: Level) -> bool:
	if level == null or level.resource_path == "": return false
	return "hometown" in level.resource_path.to_lower()

func _get_primary_player_identity() -> Dictionary:
	var identity = {"path": "", "name": ""}
	if _context == null or _context.player_roster == null: return identity
	for scene in _context.player_roster.units:
		if scene == null: continue
		identity["path"] = scene.resource_path
		var instance = scene.instantiate()
		if instance is Unit: identity["name"] = instance.unit_name
		if instance is Node: instance.queue_free()
		return identity
	return identity

func _should_skip_neutral_spawn(scene: PackedScene, leader_scene_path: String, leader_unit_name: String, _entry_coord: Vector2i) -> bool:
	if scene == null: return false
	if not leader_scene_path.is_empty() and scene.resource_path == leader_scene_path: return true
	if leader_unit_name.is_empty(): return false
	var instance = scene.instantiate()
	var should_skip = (instance is Unit and instance.unit_name == leader_unit_name)
	if instance is Node: instance.queue_free()
	return should_skip

func _spawn_hometown_player_leader(level: Level, leader_scene_path: String, leader_unit_name: String) -> Dictionary:
	var result := {"success": false, "scene_path": leader_scene_path, "unit_name": leader_unit_name, "coord": Vector2i(-999, -999)}
	if level == null: return result
	var info := _find_hometown_leader_entry(level, leader_scene_path, leader_unit_name)
	if info.is_empty(): return result
	var leader_scene: PackedScene = info.get("scene")
	if leader_scene == null: return result
	var coord: Vector2i = info.get("coord", Vector2i(-999, -999))
	var resolved_name := leader_unit_name
	if resolved_name.is_empty():
		var instance = leader_scene.instantiate()
		if instance is Unit: resolved_name = instance.unit_name
		if instance is Node: instance.queue_free()
	print_debug("[LevelContentSpawner] Spawning hometown leader as player at %s" % [coord])
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
			if entry == null: continue
			if _scene_matches_leader(entry.unit_scene, leader_scene_path, leader_unit_name):
				return {"scene": entry.unit_scene, "coord": entry.coord}
	elif not level.neutral_spawns.is_empty():
		for entry in level.neutral_spawns:
			if entry == null: continue
			var parsed := SpawnUtils.parse_entry(entry)
			if _scene_matches_leader(parsed.scene, leader_scene_path, leader_unit_name):
				return {"scene": parsed.scene, "coord": parsed.coord}
	return result

func _scene_matches_leader(scene: PackedScene, leader_scene_path: String, leader_unit_name: String) -> bool:
	if scene == null: return false
	if not leader_scene_path.is_empty() and scene.resource_path == leader_scene_path: return true
	if leader_unit_name.is_empty(): return false
	var instance = scene.instantiate()
	var matches = (instance is Unit and instance.unit_name == leader_unit_name)
	if instance is Node: instance.queue_free()
	return matches

func _ensure_leader_scene_recorded(scene: PackedScene, canonical_path: String = "", leader_unit_name: String = "") -> void:
	if _context == null or _context.player_roster == null or scene == null: return
	for existing in _context.player_roster.units:
		if existing == scene: return
		if not canonical_path.is_empty() and existing.resource_path == canonical_path: return
	_context.player_roster.units.insert(0, scene)
	_context.leader_unit_name = leader_unit_name

func _ensure_leader_scene_recorded_orig(scene: PackedScene, canonical_path: String = "", leader_unit_name: String = "") -> void:
	# Duplicate for safety during migration
	_ensure_leader_scene_recorded(scene, canonical_path, leader_unit_name)
