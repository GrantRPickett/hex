extends GdUnitTestSuite

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")

func test_get_neighbor_offsets_for_odd_column_includes_down_right() -> void:
	var neighbors = HexNavigator.get_neighbor_offsets(Vector2i(1, 1), TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(neighbors).contains(Vector2i(1, 1))
	assert_array(neighbors).contains(Vector2i(-1, 1))
	assert_array(neighbors).excludes(Vector2i(-1, -1))

func test_get_neighbor_offsets_for_even_column_excludes_down_right_diagonal() -> void:
	var neighbors = HexNavigator.get_neighbor_offsets(Vector2i(2, 1), TileSet.TILE_OFFSET_AXIS_VERTICAL)
	assert_array(neighbors).contains(Vector2i(1, -1))
	assert_array(neighbors).contains(Vector2i(1, 0))
	assert_array(neighbors).excludes(Vector2i(1, 1))
