extends GdUnitTestSuite

var _navigator
var _grid: TileMapLayer
var _tile_set: TileSet
var _actions := ["move_q", "move_w", "move_e", "move_a", "move_s", "move_d", "select_next", "select_unit_1", "toggle_free_cam"]
var _action_keys := {
	"move_q": KEY_Q,
	"move_w": KEY_W,
	"move_e": KEY_E,
	"move_a": KEY_A,
	"move_s": KEY_S,
	"move_d": KEY_D
}

func before_test() -> void:
	_navigator = auto_free(load("res://Gameplay/hex_navigator.gd").new())
	_tile_set = auto_free(TileSet.new())
	_tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	_tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	_tile_set.tile_size = Vector2i(64, 64)
	_grid = auto_free(TileMapLayer.new())
	_grid.tile_set = _tile_set
	for action in _actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if _action_keys.has(action):
			var ev = InputEventKey.new()
			ev.keycode = _action_keys[action]
			InputMap.action_add_event(action, ev)

func after_test() -> void:
	for action in _actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)

func test_get_direction_map_returns_valid_actions() -> void:
	var map = _navigator.get_direction_map(Vector2i(0, 0), _grid)


	assert_dict(map).contains_keys([
		"move_q", "move_w", "move_e",
		"move_a", "move_s", "move_d"
	])
	assert_int(map.size()).is_equal(6)

func test_cache_analog_vectors_populates_internal_state() -> void:
	# Ensure caching runs without error and populates internal state
	_navigator.cache_analog_vectors(_grid)


	# Verify a simple mapping works (0 rotation)
	# move_w is typically Up/North-West
	var mapped = _navigator.map_action_by_camera("move_w", Vector2i(0, 0), 0.0, _grid)
	assert_str(mapped).is_equal("move_w")

func test_map_action_by_camera_with_rotation() -> void:
	_navigator.cache_analog_vectors(_grid)


	# Rotate 180 degrees (PI)
	# "move_w" (Up-ish) should become "move_s" (Down-ish)
	var mapped = _navigator.map_action_by_camera("move_w", Vector2i(0, 0), PI, _grid)
	assert_str(mapped).is_equal("move_s")

func test_get_action_from_joy_axis_no_rotation() -> void:
	_navigator.cache_analog_vectors(_grid)


	# Simulate Stick UP (0, -1)
	var axis = Vector2(0, -1)
	var action = _navigator.get_action_from_joy_axis(axis, 0.0, Vector2i(0, 0), _grid)


	# Should map to an upward action (move_w or move_e usually), definitely not move_s
	assert_str(action).is_not_equal("move_s")
	assert_str(action).is_not_empty()

func test_get_action_from_joy_axis_with_rotation() -> void:
	_navigator.cache_analog_vectors(_grid)


	# Camera rotated 180 deg. Stick UP (0, -1) -> World DOWN (0, 1)
	var axis = Vector2(0, -1)
	var action = _navigator.get_action_from_joy_axis(axis, PI, Vector2i(0, 0), _grid)


	assert_str(action).is_equal("move_s")
