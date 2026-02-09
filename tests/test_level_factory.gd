# Centralized factory for creating test levels to reduce boilerplate
extends RefCounted

class TestLevel:
	var player_starts: Array[Vector2i] = []
	var goal_coords: Array[Vector2i] = []
	var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var initial_rotation: float = 0.0
	var grid_width: int = 7
	var grid_height: int = 7

static func create_default() -> TestLevel:
	return TestLevel.new()

static func create_with_player_goal(
	player_start: Vector2i,
	goal: Vector2i
) -> TestLevel:
	var level = TestLevel.new()
	level.player_starts = [player_start]
	level.goal_coords = [goal]
	return level

static func create_multi_unit(
	player_starts: Array[Vector2i],
	goal_coords: Array[Vector2i]
) -> TestLevel:
	var level = TestLevel.new()
	level.player_starts = player_starts
	level.goal_coords = goal_coords
	return level

static func create_custom(
	player_starts: Array[Vector2i],
	goal_coords: Array[Vector2i],
	grid_width: int,
	grid_height: int
) -> TestLevel:
	var level = TestLevel.new()
	level.player_starts = player_starts
	level.goal_coords = goal_coords
	level.grid_width = grid_width
	level.grid_height = grid_height
	return level
