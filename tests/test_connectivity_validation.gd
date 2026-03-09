extends GdUnitTestSuite

const _LevelRowValidator := preload("res://level/level_row_validator.gd")
const _Level := preload("res://level/Level.gd")
const _LevelTerrainData := preload("res://level/level_terrain_data.gd")
const _LevelUnitSpawnEntry := preload("res://level/level_unit_spawn_entry.gd")
const _LevelTaskEntry := preload("res://level/level_task_entry.gd")

func test_connectivity_failure_with_ring() -> void:
	var validator := _LevelRowValidator.new()
	var level := _Level.new()
	level.terrain_data = _LevelTerrainData.new()
	level.terrain_data.grid_width = 5
	level.terrain_data.grid_height = 5
	level.terrain_data.terrain_rows = [
		"GGGGG",
		"GWWWG",
		"GWGWG",
		"GWWWG",
		"GGGGG"
	]

	var player_start := _LevelUnitSpawnEntry.new()
	player_start.faction = Unit.Faction.PLAYER
	player_start.coord = Vector2i(1, 1)

	var trapped_location := _LevelTaskEntry.new()
	trapped_location.coord = Vector2i(3, 3)
	trapped_location.resource_path = "res://trapped.tres"

	var errors := validator.validate(level, "test_level", [], [], [trapped_location], [player_start], [], [])

	assert_bool(errors.is_empty()).is_false()
	assert_int(errors.size()).is_greater_equal(1)
	assert_bool(errors.any(func(e): return String(e).contains("unreachable"))).is_true()

func test_connectivity_success_no_ring() -> void:
	var validator := _LevelRowValidator.new()
	var level := _Level.new()
	level.terrain_data = _LevelTerrainData.new()
	level.terrain_data.grid_width = 5
	level.terrain_data.grid_height = 5
	level.terrain_data.terrain_rows = [
		"GGGGG",
		"GGGGG",
		"GGGGG",
		"GGGGG",
		"GGGGG"
	]

	var player_start := _LevelUnitSpawnEntry.new()
	player_start.faction = Unit.Faction.PLAYER
	player_start.coord = Vector2i(1, 1)

	var target_location := _LevelTaskEntry.new()
	target_location.coord = Vector2i(3, 3)
	target_location.resource_path = "res://target.tres"

	var errors := validator.validate(level, "test_level", [], [], [target_location], [player_start], [], [])

	assert_bool(errors.is_empty()).is_true()

func test_connectivity_failure_start_impassable() -> void:
	var validator := _LevelRowValidator.new()
	var level := _Level.new()
	level.terrain_data = _LevelTerrainData.new()
	level.terrain_data.grid_width = 5
	level.terrain_data.grid_height = 5
	level.terrain_data.terrain_rows = [
		"WGGGG",
		"GGGGG",
		"GGGGG",
		"GGGGG",
		"GGGGG"
	]

	var player_start := _LevelUnitSpawnEntry.new()
	player_start.faction = Unit.Faction.PLAYER
	player_start.coord = Vector2i(0, 0) # This is 'W'

	var target_location := _LevelTaskEntry.new()
	target_location.coord = Vector2i(3, 3)
	target_location.resource_path = "res://target.tres"

	var errors := validator.validate(level, "test_level", [], [], [target_location], [player_start], [], [])

	assert_bool(errors.is_empty()).is_false()
	assert_bool(errors.any(func(e): return String(e).contains("impassable terrain"))).is_true()
