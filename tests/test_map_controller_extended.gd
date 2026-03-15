extends GdUnitTestSuite

const MapControllerScript = preload("res://Gameplay/map/map_controller.gd")
const DisplayOrientationScript = preload("res://Gameplay/map/display_orientation.gd")

func test_map_controller_build_grid() -> void:
	var mc = auto_free(MapControllerScript.new())

	# add some internal struct so it doesn't crash
	var terrain_map: Node = Node.new()
	terrain_map.name = "TerrainMap"
	mc.add_child(terrain_map)
	mc.terrain_map = terrain_map

	var grid_visuals: Node = Node.new()
	grid_visuals.name = "GridVisuals"
	mc.add_child(grid_visuals)
	mc.grid_visuals = grid_visuals

	mc.build_grid(Vector2i(5, 5))
	assert_object(mc.grid).is_not_null()

	mc.rebuild_grid(Vector2i(10, 10))
	assert_object(mc.grid).is_not_null()
