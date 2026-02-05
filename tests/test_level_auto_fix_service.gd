extends GdUnitTestSuite

const LevelAutoFixService := preload("res://Resources/level_data/level_auto_fix_service.gd")
const LevelAutoFixOptions := preload("res://Resources/level_data/level_auto_fix_options.gd")
const Level := preload("res://Resources/Level.gd")
const LevelGoalEntry := preload("res://Resources/level_data/level_goal_entry.gd")
const LevelGoalRow := preload("res://Resources/level_data/level_goal_row.gd")
const LevelStartRow := preload("res://Resources/level_data/level_start_row.gd")
const LevelUnitSpawnEntry := preload("res://Resources/level_data/level_unit_spawn_entry.gd")

func _make_level(rows: Array[String]) -> Level:
	var level := Level.new()
	level.terrain_data.grid_width = rows[0].length()
	level.terrain_data.grid_height = rows.size()
	level.terrain_data.terrain_rows = rows
	return level

func _make_report_stub() -> Dictionary:
	return {
		"applied": [],
		"failed": [],
		"messages": [],
		"summary": "",
		"report_path": "",
	}

func test_apply_moves_goal_from_impassable_tile() -> void:
	var level := _make_level(["WG", "GG"])
	var goal := LevelGoalEntry.new()
	goal.coord = Vector2i(0, 0)
	goal.goal_scene = load("res://Gameplay/goal.tscn")
	level.goals = [goal]
	var row := LevelGoalRow.new()
	row.level_id = &"demo"
	row.coord = Vector2i(0, 0)
	row.goal_scene = goal.goal_scene
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	var service: LevelAutoFixService = LevelAutoFixService.new()
	var report := service.apply(level, &"demo", [], [row], [], options)
	assert_bool(report != null).is_true()
	assert_that(level.goals[0].coord).is_equal(Vector2i(1, 1))

func test_apply_relocates_overlapping_player_start() -> void:
	var level := _make_level(["GG", "GG"])
	var players: Array[Vector2i] = []
	players.append(Vector2i(0, 0))
	players.append(Vector2i(0, 0))
	level.player_starts = players
	var row_a := LevelStartRow.new()
	row_a.level_id = &"demo"
	row_a.slot_index = 0
	row_a.coord = Vector2i(0, 0)
	var row_b := LevelStartRow.new()
	row_b.level_id = &"demo"
	row_b.slot_index = 1
	row_b.coord = Vector2i(0, 0)
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	var service: LevelAutoFixService = LevelAutoFixService.new()
	var report := service.apply(level, &"demo", [], [], [row_a, row_b], options)
	assert_bool(report != null).is_true()
	assert_that(level.player_starts[1]).is_equal(Vector2i(1, 1))
	assert_int(report.get("applied", []).size()).is_equal(1)

func test_build_context_exposes_helpers() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG", "GG"])
	var context := service._build_context(level, &"demo")
	assert_bool(context.is_empty()).is_false()
	var is_in_bounds: Callable = context["is_in_bounds"]
	assert_bool(is_in_bounds.call(Vector2i(1, 1))).is_true()
	var is_passable: Callable = context["is_passable"]
	assert_bool(is_passable.call(Vector2i(0, 0))).is_true()

func test_repair_goals_updates_report() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["WG", "GG"])
	var goal := LevelGoalEntry.new()
	goal.coord = Vector2i(0, 0)
	goal.goal_scene = load("res://Gameplay/goal.tscn")
	level.goals = [goal]
	var row := LevelGoalRow.new()
	row.level_id = &"demo"
	row.coord = Vector2i(0, 0)
	row.goal_scene = goal.goal_scene
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var rows: Array[LevelGoalRow] = []
	rows.append(row)
	service._repair_goals(level, rows, report, context)
	assert_int(report["applied"].size()).is_equal(1)

func test_repair_player_starts_handles_overlap() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG", "GG"])
	level.player_starts = [Vector2i(0, 0), Vector2i(0, 0)]
	var row_a := LevelStartRow.new()
	row_a.level_id = &"demo"
	row_a.slot_index = 0
	row_a.coord = Vector2i(0, 0)
	var row_b := LevelStartRow.new()
	row_b.level_id = &"demo"
	row_b.slot_index = 1
	row_b.coord = Vector2i(0, 0)
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var player_rows: Array[LevelStartRow] = []
	player_rows.append(row_a)
	player_rows.append(row_b)
	service._repair_player_starts(level, player_rows, report, context)
	assert_that(level.player_starts[1]).is_equal(Vector2i(1, 1))

func test_repair_neutral_starts_updates_entries() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG", "GG"])
	var entry := LevelUnitSpawnEntry.new()
	entry.coord = Vector2i(-1, 0)
	level.set("neutral_spawns", [entry])
	var row := LevelStartRow.new()
	row.level_id = &"demo"
	row.slot_index = 0
	row.coord = Vector2i(0, 0)
	row.faction = &"neutral"
	row.unit_scene = load("res://Gameplay/generic_enemy.tscn")
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var neutral_rows: Array[LevelStartRow] = []
	neutral_rows.append(row)
	service._repair_neutral_starts(level, neutral_rows, report, context)
	var neutral_entries: Array = level.get("neutral_spawns")
	assert_that(neutral_entries[0].coord).is_equal(Vector2i(1, 1))
