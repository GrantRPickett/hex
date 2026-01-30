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

