extends GdUnitTestSuite

# Tests for TerrainTile covering:
#   - get_hover_info()
#   - get_modified_movement_cost() with and without WeatherAttribute
#
# TerrainTile extends Node2D but can be instantiated in tests without a scene tree.

const TerrainTileScript := preload("res://Gameplay/terrain/terrain_tile.gd")
const WeatherAttributeScript := preload("res://Resources/weather/WeatherAttribute.gd")

func _make_tile() -> TerrainTile:
	var t: TerrainTile = TerrainTileScript.new()
	add_child(t) # Needed to satisfy Node2D lifecycle
	return t

func _make_weather(humidity: float = 0.0, temperature: float = 0.0, move_modifier: float = 0.0) -> WeatherAttribute:
	var w: WeatherAttribute = WeatherAttributeScript.new()
	w.humidity_effect = humidity
	w.temperature_effect = temperature
	w.movement_cost_modifier = move_modifier
	auto_free(w)
	return w

func after_test() -> void:
	# Clean up any children added during tests
	for child in get_children():
		child.queue_free()

# ---------------------------------------------------------------------------
# get_hover_info
# ---------------------------------------------------------------------------

func test_hover_info_passable_no_modifiers() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	tile.status_effect = &""
	tile.blocks_action_after_move = false
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Terrain:")
	assert_str(info).is_not_contains("Impassable")
	assert_str(info).is_not_contains("Penalty")
	assert_str(info).is_not_contains("Bonus")

func test_hover_info_impassable_shows_impassable() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = false
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Impassable")

func test_hover_info_movement_penalty_shown() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.movement_penalty = 2
	tile.movement_bonus = 0
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Movement Penalty: 2")

func test_hover_info_movement_bonus_shown() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.movement_penalty = 0
	tile.movement_bonus = 1
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Movement Bonus: 1")

func test_hover_info_status_effect_shown() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.status_effect = &"slippery"
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Status Effect: slippery")

func test_hover_info_blocks_action_shown() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.blocks_action_after_move = true
	var info := tile.get_hover_info()
	assert_str(info).is_contains("Blocks action after move")

func test_hover_info_penalty_hidden_when_impassable() -> void:
	# Penalty/bonus not shown for impassable tiles (branch only when passable)
	var tile: TerrainTile = _make_tile()
	tile.passable = false
	tile.movement_penalty = 3
	var info := tile.get_hover_info()
	assert_str(info).is_not_contains("Penalty")

# ---------------------------------------------------------------------------
# get_modified_movement_cost — no weather
# ---------------------------------------------------------------------------

func test_movement_cost_no_weather_no_modifiers() -> void:
	var tile: TerrainTile = _make_tile()
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	var cost := tile.get_modified_movement_cost(null)
	assert_int(cost).is_equal(1)

func test_movement_cost_no_weather_with_penalty() -> void:
	var tile: TerrainTile = _make_tile()
	tile.movement_penalty = 2
	tile.movement_bonus = 0
	var cost := tile.get_modified_movement_cost(null)
	assert_int(cost).is_equal(3) # 1 + 2 - 0

func test_movement_cost_no_weather_with_bonus() -> void:
	var tile: TerrainTile = _make_tile()
	tile.movement_penalty = 0
	tile.movement_bonus = 1
	var cost := tile.get_modified_movement_cost(null)
	# max(1, 1 + 0 - 1) = max(1, 0) = 1
	assert_int(cost).is_equal(1)

func test_movement_cost_minimum_is_one() -> void:
	var tile: TerrainTile = _make_tile()
	tile.movement_penalty = 0
	tile.movement_bonus = 99
	var cost := tile.get_modified_movement_cost(null)
	assert_int(cost).is_greater_equal(1)

# ---------------------------------------------------------------------------
# get_modified_movement_cost — with weather
# ---------------------------------------------------------------------------

func test_movement_cost_weather_move_modifier_increases_cost() -> void:
	var tile: TerrainTile = _make_tile()
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	# base_cost = 1; modifier = 1.0 → added cost = roundi(1 * 1.0) = 1
	var weather: WeatherAttribute = _make_weather(0.0, 0.0, 1.0)
	var cost := tile.get_modified_movement_cost(weather)
	assert_int(cost).is_equal(2)

func test_movement_cost_very_wet_adds_one_for_passable() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.status_effect = &""
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	var weather: WeatherAttribute = _make_weather(0.6, 0.0, 0.0) # humidity > 0.5
	var cost := tile.get_modified_movement_cost(weather)
	# base=1, +0 from modifier, +1 from wet = 2
	assert_int(cost).is_equal(2)

func test_movement_cost_very_cold_adds_one_for_passable() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	var weather: WeatherAttribute = _make_weather(0.0, -0.6, 0.0) # temperature < -0.5
	var cost := tile.get_modified_movement_cost(weather)
	# base=1, +1 from cold = 2
	assert_int(cost).is_equal(2)

func test_movement_cost_neutral_weather_unchanged() -> void:
	var tile: TerrainTile = _make_tile()
	tile.passable = true
	tile.movement_penalty = 0
	tile.movement_bonus = 0
	var weather: WeatherAttribute = _make_weather(0.0, 0.0, 0.0)
	var cost := tile.get_modified_movement_cost(weather)
	assert_int(cost).is_equal(1)
