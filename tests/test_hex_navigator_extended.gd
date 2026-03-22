extends GdUnitTestSuite

const HexNavigatorScript := preload("res://Gameplay/map/hex_navigator.gd")

class FakeTileSet:
	var tile_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL

class FakeGrid:
	var tile_set := FakeTileSet.new()
	func map_to_local(coord: Vector2i) -> Vector2:
		# Just mock some basic coordinates
		var q = coord.x
		var r = coord.y - (coord.x >> 1)
		var cx = q * 64.0
		var cy = r * 64.0 + (32.0 if q % 2 != 0 else 0.0)
		return Vector2(cx, cy)

func test_cache_analog_vectors() -> void:
	var nav: HexNavigatorScript = HexNavigatorScript.new()
	var grid: FakeGrid = FakeGrid.new()

	nav.cache_analog_vectors(grid)

	assert_bool(nav._action_vectors.is_empty()).is_false()
	assert_bool(nav._action_vectors.has("move_w")).is_true()
	assert_bool(nav._action_vectors.has("move_e")).is_true()

func test_get_action_from_joy_axis() -> void:
	var nav: HexNavigatorScript = HexNavigatorScript.new()
	var grid: FakeGrid = FakeGrid.new()

	var action: String = nav.get_action_from_joy_axis(Vector2(1.0, 0.0), 0.0, Vector2i(0, 0), grid)
	assert_str(action).is_not_empty()

	var dead_action: String = nav.get_action_from_joy_axis(Vector2(0.01, 0.0), 0.0, Vector2i(0, 0), grid)
	assert_str(dead_action).is_empty()
