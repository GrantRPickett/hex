# test_grid_visuals_committed_path_preview.gd
extends GdUnitTestSuite

func test_set_committed_path_preview_sets_line_points() -> void:
	var grid := auto_free(TileMapLayer.new())
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	grid.tile_set = ts

	var visuals := auto_free(GridVisuals.new())
	get_tree().root.add_child(visuals)
	visuals._ready()

	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	visuals.set_committed_path_preview(grid, path)

	var line := visuals.get_node("CommittedPathLine") as Line2D
	assert_object(line).is_not_null()
	assert_bool(line.visible).is_true()
	assert_int(line.points.size()).is_equal(3)

	# Clearing
	visuals.set_committed_path_preview(grid, [])
	assert_bool(line.visible).is_false()

