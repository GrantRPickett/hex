extends GdUnitTestSuite

const LevelResource := preload("res://Resources/Level.gd")
const LootListDefinitionResource := preload("res://Resources/loot_lists/loot_list_definition.gd")
const LevelLootEntryResource := preload("res://Resources/level_data/level_loot_entry.gd")
const PlayerRosterResource := preload("res://Gameplay/player_roster.gd")
const EnemyRosterResource := preload("res://Gameplay/enemy_roster.gd")
const NeutralRosterResource := preload("res://Gameplay/neutral_roster.gd")
const UnitRosterDefinitionResource := preload("res://Resources/rosters/unit_roster_definition.gd")
const LevelUnitSpawnEntryResource := preload("res://Resources/level_data/level_unit_spawn_entry.gd")
const InventoryItemResource := preload("res://Gameplay/inventory_item.gd")
const Unit := preload("res://Gameplay/unit.gd")

class LegacyLootLevel extends Level:
	var loot: Array = []

class RecordingLevelBuilder extends LevelBuilder:
	var spawned_scene_order: Array[StringName] = []

	func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE) -> void:
		spawned_scene_order.append(scene.resource_name)

func _make_stub_scene(label: String) -> PackedScene:
	var scene := PackedScene.new()
	scene.resource_name = label
	var node := Node2D.new()
	node.name = label
	scene.pack(node)
	node.queue_free()
	return scene

func _make_unit_scene_with_willpower(current: int, max_value: int) -> PackedScene:
	var unit := Unit.new()
	unit.unit_name = "TestUnit"
	unit.max_willpower = max_value
	unit.willpower = current
	var scene := PackedScene.new()
	scene.pack(unit)
	unit.queue_free()
	return scene

func test_spawn_roster_units_cycles_enemy_roster_entries() -> void:
	var builder := RecordingLevelBuilder.new(null)
	var scenes: Array[PackedScene] = [_make_stub_scene("enemy_a"), _make_stub_scene("enemy_b")]
	var starts: Array = [Vector2i.ZERO, Vector2i.ONE]
	builder._spawn_roster_units(starts, scenes, false, false)
	assert_array(builder.spawned_scene_order).contains_exactly(["enemy_a", "enemy_b"])

func test_spawn_roster_units_wraps_when_more_spawns_than_scenes() -> void:
	var builder := RecordingLevelBuilder.new(null)
	var scenes: Array[PackedScene] = [_make_stub_scene("enemy_a"), _make_stub_scene("enemy_b")]
	var starts: Array = [Vector2i.ZERO, Vector2i.ONE, Vector2i(2, 2)]
	builder._spawn_roster_units(starts, scenes, false, false)
	assert_array(builder.spawned_scene_order).contains_exactly(["enemy_a", "enemy_b", "enemy_a"])
func test_player_roster_stops_when_units_exhausted() -> void:
	var builder := RecordingLevelBuilder.new(null)
	var scenes: Array[PackedScene] = [_make_stub_scene("player_only")]
	var starts: Array = [Vector2i.ZERO, Vector2i.ONE]
	builder._spawn_roster_units(starts, scenes, true, false)
	assert_array(builder.spawned_scene_order).contains_exactly(["player_only"])

func test_spawn_unit_resets_player_willpower_to_max() -> void:
	var context := _make_level_build_context()
	var builder := LevelBuilder.new(context)
	var scene := _make_unit_scene_with_willpower(2, 7)
	builder._spawn_unit(scene, Vector2i.ZERO, true, false)
	var player_units := context.unit_manager.get_player_units()
	assert_int(player_units.size()).is_equal(1)
	var player := player_units[0]
	assert_int(player.willpower).is_equal(player.max_willpower)
	_cleanup_level_build_context(context)

func test_spawn_unit_does_not_change_enemy_willpower() -> void:
	var context := _make_level_build_context()
	var builder := LevelBuilder.new(context)
	var scene := _make_unit_scene_with_willpower(3, 10)
	builder._spawn_unit(scene, Vector2i.ZERO, false, false)
	var enemy_units := context.unit_manager.get_enemy_units()
	assert_int(enemy_units.size()).is_equal(1)
	var enemy := enemy_units[0]
	assert_int(enemy.willpower).is_equal(3)
	assert_int(enemy.max_willpower).is_equal(10)
	_cleanup_level_build_context(context)


class FakeTerrainMap extends RefCounted:
	var blocked := {}

	func is_passable(coord: Vector2i) -> bool:
		return not blocked.get(coord, false)

	func set_offset_axis(_axis: int) -> void:
		pass

	func load_from_rows(_rows: Array[String], _w: int, _h: int) -> void:
		pass

class LoggingLevelBuilder extends LevelBuilder:
	var logged: Array[Vector2i] = []

	func _log_impassable_location(coord: Vector2i) -> void:
		logged.append(coord)


func test_logs_when_location_on_impassable_tile() -> void:
	var builder := LoggingLevelBuilder.new(null)
	var fake_map := FakeTerrainMap.new()
	fake_map.blocked[Vector2i.ONE] = true
	builder._terrain_map = fake_map
	assert_bool(builder._is_location_coord_passable(Vector2i.ONE)).is_false()
	assert_array(builder.logged).contains_exactly([Vector2i.ONE])

func test_location_passable_when_tile_allows() -> void:
	var builder := LoggingLevelBuilder.new(null)
	var fake_map := FakeTerrainMap.new()
	builder._terrain_map = fake_map
	assert_bool(builder._is_location_coord_passable(Vector2i(2, 3))).is_true()
	assert_array(builder.logged).is_empty()
func test_build_resets_loot_manager_before_spawning() -> void:
	var context := _make_level_build_context()
	var builder := LevelBuilder.new(context)
	var existing_item := InventoryItemResource.new()
	existing_item.item_name = "Existing"
	context.loot_manager.spawn_loot(Vector2i.ZERO, [existing_item])

	var loot_entry := LevelLootEntryResource.new()
	loot_entry.coord = Vector2i(2, 3)
	loot_entry.items = [InventoryItemResource.new()]
	var definition := LootListDefinitionResource.new()
	definition.loot_entries = [loot_entry]
	var level := LevelResource.new()
	level.loot_list_definition = definition

	builder.build(level, null)

	assert_object(context.loot_manager.get_loot_at(Vector2i.ZERO)).is_null()
	assert_object(context.loot_manager.get_loot_at(loot_entry.coord)).is_not_null()
	assert_int(context.loot_manager.get_loot_count()).is_equal(1)

	_cleanup_level_build_context(context)

func test_spawn_loot_handles_legacy_loot_data() -> void:
	var context := _make_level_build_context()
	var builder := LevelBuilder.new(context)
	var level := LegacyLootLevel.new()
	var legacy_item := InventoryItemResource.new()
	legacy_item.item_name = "Legacy"
	var legacy_entry := {
		"coord": Vector2i(5, 1),
		"items": [legacy_item]
	}
	level.loot = [legacy_entry]

	builder._spawn_loot(level)

	var loot := context.loot_manager.get_loot_at(Vector2i(5, 1))
	assert_object(loot).is_not_null()
	assert_int(context.loot_manager.get_loot_count()).is_equal(1)

	_cleanup_level_build_context(context)

func test_hometown_neutral_roster_skips_by_unit_name() -> void:
	var context := _make_level_build_context()
	context.level_path = "res://Resources/levels/hometown.tres"
	var leader_scene := _make_unit_scene_with_name("LeaderFace")
	context.player_roster.units = [leader_scene]
	context.leader_unit_name = "LeaderFace"
	var neutral_definition := UnitRosterDefinitionResource.new()
	var duplicate_entry := LevelUnitSpawnEntryResource.new()
	duplicate_entry.unit_scene = _make_unit_scene_with_name("LeaderFace")
	neutral_definition.spawn_entries = [duplicate_entry]
	var level := LevelResource.new()
	level.neutral_roster_definition = neutral_definition
	var builder := RecordingLevelBuilder.new(context)
	builder._spawn_units(level)
	assert_array(builder.spawned_scene_order).contains_exactly([StringName("LeaderFace")])
	_cleanup_level_build_context(context)

func test_hometown_neutral_roster_skips_player_leader_scene() -> void:
	var context := _make_level_build_context()
	context.level_path = "res://Resources/levels/hometown.tres"
	var leader_scene := _make_stub_scene("Leader")
	var ally_scene := _make_stub_scene("Ally")
	context.player_roster.units = [leader_scene]
	context.leader_unit_name = "Leader"
	var neutral_definition := UnitRosterDefinitionResource.new()
	var leader_entry := LevelUnitSpawnEntryResource.new()
	leader_entry.coord = Vector2i.ZERO
	leader_entry.unit_scene = leader_scene
	var ally_entry := LevelUnitSpawnEntryResource.new()
	ally_entry.coord = Vector2i.ONE
	ally_entry.unit_scene = ally_scene
	neutral_definition.spawn_entries = [leader_entry, ally_entry]
	var level := LevelResource.new()
	level.neutral_roster_definition = neutral_definition
	var builder := RecordingLevelBuilder.new(context)
	builder._spawn_units(level)
	assert_array(builder.spawned_scene_order).contains_exactly([StringName("Leader"), StringName("Ally")])
	_cleanup_level_build_context(context)

func test_should_skip_neutral_spawn_by_hometown_coord() -> void:
	var builder := LevelBuilder.new(null)
	var scene := _make_stub_scene('NeutralLeader')
	var should_skip := builder._should_skip_neutral_spawn(scene, '', '', Vector2i(3, 2), Vector2i(3, 2))
	assert_bool(should_skip).is_true()

func test_hometown_spawns_player_leader_unit() -> void:
	var context := _make_level_build_context()
	context.level_path = "res://Resources/levels/hometown.tres"
	var leader_scene := _make_unit_scene_with_name("LeaderFace")
	context.player_roster.units.clear()
	context.leader_unit_name = "LeaderFace"
	var leader_entry := LevelUnitSpawnEntryResource.new()
	leader_entry.coord = Vector2i(4, 2)
	leader_entry.unit_scene = leader_scene
	var neutral_definition := UnitRosterDefinitionResource.new()
	neutral_definition.spawn_entries = [leader_entry]
	var level := LevelResource.new()
	level.neutral_roster_definition = neutral_definition
	var builder := LevelBuilder.new(context)
	builder._spawn_units(level)
	var players := context.unit_manager.get_player_units()
	assert_int(players.size()).is_equal(1)
	assert_str(players[0].unit_name).is_equal("LeaderFace")
	var player_index := context.unit_manager.get_unit_index(players[0])
	assert_vector(context.unit_manager.get_coord(player_index)).is_equal(Vector2i(4, 2))
	assert_int(context.unit_manager.get_neutral_units().size()).is_equal(0)
	assert_int(context.player_roster.units.size()).is_greater(0)
	_cleanup_level_build_context(context)

func test_hometown_leader_not_duplicated_in_roster() -> void:
	var context := _make_level_build_context()
	context.level_path = "res://Resources/levels/hometown.tres"
	var leader_scene := _make_unit_scene_with_name("LeaderFace")
	context.player_roster.units = [leader_scene]
	context.leader_unit_name = "LeaderFace"
	var leader_entry := LevelUnitSpawnEntryResource.new()
	leader_entry.coord = Vector2i(2, 2)
	leader_entry.unit_scene = leader_scene
	var neutral_definition := UnitRosterDefinitionResource.new()
	neutral_definition.spawn_entries = [leader_entry]
	var level := LevelResource.new()
	level.neutral_roster_definition = neutral_definition
	var builder := LevelBuilder.new(context)
	builder._spawn_units(level)
	assert_int(context.player_roster.units.size()).is_equal(1)
	assert_int(context.unit_manager.get_player_units().size()).is_equal(1)
	assert_int(context.unit_manager.get_neutral_units().size()).is_equal(0)
	_cleanup_level_build_context(context)

func _make_level_build_context() -> LevelBuildContext:
	var context := LevelBuildContext.new(
		Node2D.new(),
		UnitManager.new(),
		LocationManager.new(),
		LootManager.new(),
		CombatSystem.new(),
		Node2D.new(),
		Camera2D.new(),
		Node.new(),
		PlayerRosterResource.new(),
		EnemyRosterResource.new(),
		NeutralRosterResource.new()
	)
	context.allow_loot_spawn = true
	context.leader_unit_name = "Scout"
	return context

func _cleanup_level_build_context(context: LevelBuildContext) -> void:
	if context == null:
		return
	if context.loot_manager:
		context.loot_manager.reset()
	var nodes: Array = [
		context.gameplay_root,
		context.unit_manager,
		context.location_manager,
		context.loot_manager,
		context.combat_system,
		context.grid,
		context.camera,
		context.controls
	]
	for node in nodes:
		if node and node is Node:
			node.queue_free()

func _make_unit_scene_with_name(unit_name: String) -> PackedScene:
	var unit := Unit.new()
	unit.unit_name = unit_name
	var scene := PackedScene.new()
	scene.resource_name = unit_name
	scene.pack(unit)
	unit.queue_free()
	return scene
