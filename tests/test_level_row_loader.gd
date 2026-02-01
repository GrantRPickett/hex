extends GdUnitTestSuite

const LevelRowLoader := preload("res://Resources/level_data/level_row_loader.gd")
const LevelRosterRow := preload("res://Resources/level_data/level_roster_row.gd")
const LevelLootRow := preload("res://Resources/level_data/level_loot_row.gd")
const LevelGoalRow := preload("res://Resources/level_data/level_goal_row.gd")
const LevelTerrainRow := preload("res://Resources/level_data/level_terrain_row.gd")
const LevelStartRow := preload("res://Resources/level_data/level_start_row.gd")
const LevelDialogueRow := preload("res://Resources/level_data/level_dialogue_row.gd")
const LevelMetaRow := preload("res://Resources/level_data/level_meta_row.gd")
const Level := preload("res://Resources/Level.gd")
const LevelTerrainData := preload("res://Resources/level_data/level_terrain_data.gd")

func _create_level() -> Level:
	var level := Level.new()
	if level.terrain_data == null:
		level.terrain_data = LevelTerrainData.new()
	level.terrain_data.grid_width = 10
	level.terrain_data.grid_height = 10
	return level

func _make_terrain_rows(level_id: StringName) -> Array:
	var rows: Array = []
	for i in range(2):
		var row := LevelTerrainRow.new()
		row.level_id = level_id
		row.row_index = i
		row.row_data = "GGRRR"
		rows.append(row)
	return rows

func test_apply_rows_populates_definitions_and_new_data() -> void:
	var level_id := &"demo"
	var loader := LevelRowLoader.new()
	var roster_row := LevelRosterRow.new()
	roster_row.level_id = level_id
	roster_row.coord = Vector2i(1, 2)
	roster_row.unit_scene = load("res://Gameplay/generic_enemy.tscn")
	var loot_row := LevelLootRow.new()
	loot_row.level_id = level_id
	loot_row.coord = Vector2i(2, 2)
	loot_row.items = [load("res://Resources/items/bronze_grit.tres")]
	var goal_row := LevelGoalRow.new()
	goal_row.level_id = level_id
	goal_row.coord = Vector2i(3, 3)
	goal_row.goal_scene = load("res://Gameplay/goal.tscn")
	var start_row := LevelStartRow.new()
	start_row.level_id = level_id
	start_row.faction = &"player"
	start_row.slot_index = 0
	start_row.coord = Vector2i(0, 0)
	var dialogue_row := LevelDialogueRow.new()
	dialogue_row.level_id = level_id
	dialogue_row.entry_id = &"intro"
	dialogue_row.coord = Vector2i(1, 0)
	dialogue_row.timeline_path = "res://Resources/dialogue/hometown_intro.dtl"
	var meta_row := LevelMetaRow.new()
	meta_row.level_id = level_id
	meta_row.require_all_units = true
	meta_row.hex_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	meta_row.next_level_path = "res://Resources/levels/level_2.tres"
	loader.set_row_sources([roster_row], [loot_row], [goal_row], _make_terrain_rows(level_id), [start_row], [dialogue_row], [meta_row])

	var level := _create_level()
	var errors := loader.apply_rows_to_level(level, level_id)

	assert_array(errors).is_empty()
	assert_object(level.enemy_roster_definition).is_not_null()
	assert_int(level.enemy_roster_definition.spawn_entries.size()).is_equal(1)
	assert_that(level.enemy_roster_definition.spawn_entries[0].coord).is_equal(Vector2i(1, 2))
	assert_object(level.loot_list_definition).is_not_null()
	assert_int(level.loot_list_definition.loot_entries.size()).is_equal(1)
	assert_that(level.loot_list_definition.loot_entries[0].coord).is_equal(Vector2i(2, 2))
	assert_int(level.goals.size()).is_equal(1)
	assert_that(level.goals[0].coord).is_equal(Vector2i(3, 3))
	assert_that(level.player_starts.size()).is_equal(1)
	assert_that(level.player_starts[0]).is_equal(Vector2i(0, 0))
	assert_that(level.dialogue_entries.size()).is_equal(1)
	assert_that(level.dialogue_entries[0].timeline_path).is_equal("res://Resources/dialogue/hometown_intro.dtl")
	assert_bool(level.require_all_units).is_true()
	assert_int(level.terrain_data.grid_height).is_equal(2)

func test_duplicate_roster_rows_reported() -> void:
	var loader := LevelRowLoader.new()
	var row_a := LevelRosterRow.new()
	row_a.level_id = &"demo"
	row_a.coord = Vector2i(1, 1)
	row_a.unit_scene = load("res://Gameplay/generic_enemy.tscn")
	var row_b := LevelRosterRow.new()
	row_b.level_id = &"demo"
	row_b.coord = Vector2i(1, 1)
	row_b.unit_scene = load("res://Gameplay/generic_enemy.tscn")
	loader.set_row_sources([row_a, row_b], [], [], _make_terrain_rows(&"demo"))

	var level := _create_level()
	var errors := loader.apply_rows_to_level(level, &"demo")

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate roster coordinate"))).is_true()

func test_out_of_bounds_goal_reported() -> void:
	var loader := LevelRowLoader.new()
	var goal_row := LevelGoalRow.new()
	goal_row.level_id = &"demo"
	goal_row.coord = Vector2i(99, 99)
	goal_row.goal_scene = load("res://Gameplay/goal.tscn")
	loader.set_row_sources([], [], [goal_row], _make_terrain_rows(&"demo"))

	var level := _create_level()
	level.terrain_data.grid_width = 4
	level.terrain_data.grid_height = 4
	var errors := loader.apply_rows_to_level(level, &"demo")

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("out of bounds"))).is_true()

func test_duplicate_start_coordinate_reported() -> void:
	var loader := LevelRowLoader.new()
	var start_a := LevelStartRow.new()
	start_a.level_id = &"demo"
	start_a.coord = Vector2i(0, 0)
	var start_b := LevelStartRow.new()
	start_b.level_id = &"demo"
	start_b.coord = Vector2i(0, 0)
	loader.set_row_sources([], [], [], _make_terrain_rows(&"demo"), [start_a, start_b])

	var level := _create_level()
	var errors := loader.apply_rows_to_level(level, &"demo")

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate start coordinate"))).is_true()

func test_dialogue_missing_timeline_reported() -> void:
	var loader := LevelRowLoader.new()
	var dialogue_row := LevelDialogueRow.new()
	dialogue_row.level_id = &"demo"
	dialogue_row.entry_id = &"missing"
	dialogue_row.coord = Vector2i(0, 0)
	dialogue_row.timeline_path = ""
	loader.set_row_sources([], [], [], _make_terrain_rows(&"demo"), [], [dialogue_row])

	var level := _create_level()
	var errors := loader.apply_rows_to_level(level, &"demo")

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("missing timeline"))).is_true()
