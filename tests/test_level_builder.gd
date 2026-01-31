extends GdUnitTestSuite

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

	func _log_impassable_goal(coord: Vector2i) -> void:
		logged.append(coord)


func test_logs_when_goal_on_impassable_tile() -> void:
	var builder := LoggingLevelBuilder.new(null)
	var fake_map := FakeTerrainMap.new()
	fake_map.blocked[Vector2i.ONE] = true
	builder._terrain_map = fake_map
	assert_bool(builder._is_goal_coord_passable(Vector2i.ONE)).is_false()
	assert_array(builder.logged).contains_exactly([Vector2i.ONE])

func test_goal_passable_when_tile_allows() -> void:
	var builder := LoggingLevelBuilder.new(null)
	var fake_map := FakeTerrainMap.new()
	builder._terrain_map = fake_map
	assert_bool(builder._is_goal_coord_passable(Vector2i(2, 3))).is_true()
	assert_array(builder.logged).is_empty()
