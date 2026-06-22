extends GdUnitTestSuite

func test_get_coord_returns_assigned_coord() -> void:
	var entry := LevelLocationEntry.new()
	entry.coord = Vector2i(3, 5)
	var result := entry.get_coord()
	assert_int(result.x).is_equal(3)
	assert_int(result.y).is_equal(5)

func test_get_location_scene_returns_assigned_scene() -> void:
	var entry := LevelLocationEntry.new()
	var scene := preload("res://Gameplay/scene_templates/location.tscn")
	entry.location_scene = scene
	assert_object(entry.get_location_scene()).is_same(scene)

func test_get_stats_returns_assigned_stats() -> void:
	var entry := LevelLocationEntry.new()
	var stats := CombatStats.new(1, 2, 3, 4, 5, 6, 7, 8)
	entry.stats = stats
	assert_object(entry.get_stats()).is_same(stats)