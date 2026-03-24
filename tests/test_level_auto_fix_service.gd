extends GdUnitTestSuite

const LevelAutoFixService := preload("res://level/level_auto_fix_service.gd")
const LevelAutoFixOptions := preload("res://level/level_auto_fix_options.gd")
const Level := preload("res://level/level.gd")
const LevelTaskEntry := preload("res://level/level_task_entry.gd")
const LevelUnitSpawnEntry := preload("res://level/level_unit_spawn_entry.gd")

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

func test_apply_moves_location_from_impassable_tile() -> void:
	var level := _make_level(["WG", "GG"])
	var location := LevelTaskEntry.new()
	location.coord = Vector2i(0, 0)
	location.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	level.locations = [location]
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	var service: LevelAutoFixService = LevelAutoFixService.new()
	var report := service.apply(level, &"demo", [], [location], [], [], options)
	assert_bool(report != null).is_true()
	assert_that(level.locations[0].coord).is_equal(Vector2i(1, 1))

func test_apply_relocates_overlapping_player_start() -> void:
	var level := _make_level(["GG", "GG"])
	var players: Array[Vector2i] = []
	players.append(Vector2i(0, 0))
	players.append(Vector2i(0, 0))
	level.player_starts = players
	var row_a := LevelUnitSpawnEntry.new()
	row_a.level_id = &"demo"
	row_a.slot_index = 0
	row_a.coord = Vector2i(0, 0)
	var row_b := LevelUnitSpawnEntry.new()
	row_b.level_id = &"demo"
	row_b.slot_index = 1
	row_b.coord = Vector2i(0, 0)
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	var service: LevelAutoFixService = LevelAutoFixService.new()
	var report := service.apply(level, &"demo", [], [], [row_a, row_b], [], options)
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

func test_repair_locations_updates_report() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["WG", "GG"])
	var location := LevelTaskEntry.new()
	location.coord = Vector2i(0, 0)
	location.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	level.locations = [location]
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var options := LevelAutoFixOptions.new()
	service._repair_locations(level, [location], report, context, options)
	assert_int(report["applied"].size()).is_equal(1)

func test_repair_player_starts_handles_overlap() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG", "GG"])
	level.player_starts = [Vector2i(0, 0), Vector2i(0, 0)]
	var row_a := LevelUnitSpawnEntry.new()
	row_a.level_id = &"demo"
	row_a.slot_index = 0
	row_a.coord = Vector2i(0, 0)
	var row_b := LevelUnitSpawnEntry.new()
	row_b.level_id = &"demo"
	row_b.slot_index = 1
	row_b.coord = Vector2i(0, 0)
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var player_rows: Array[LevelUnitSpawnEntry] = []
	player_rows.append(row_a)
	player_rows.append(row_b)
	var options := LevelAutoFixOptions.new()
	service._repair_player_starts(level, player_rows, report, context, options)
	assert_that(level.player_starts[1]).is_equal(Vector2i(1, 1))

func test_repair_neutral_starts_updates_entries() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG", "GG"])
	var entry := LevelUnitSpawnEntry.new()
	entry.coord = Vector2i(-1, 0)
	level.set("neutral_spawns", [entry])
	var row := LevelUnitSpawnEntry.new()
	row.level_id = &"demo"
	row.slot_index = 0
	row.coord = Vector2i(0, 0)
	row.faction = GameConstants.Faction.NEUTRAL
	row.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var neutral_rows: Array[LevelUnitSpawnEntry] = []
	neutral_rows.append(row)
	var options := LevelAutoFixOptions.new()
	service._repair_neutral_starts(level, neutral_rows, report, context, options)
	var neutral_entries: Array = level.get("neutral_spawns")
	assert_that(neutral_entries[0].coord).is_equal(Vector2i(1, 1))


func test_apply_respects_enemy_spawns_from_start_rows() -> void:
	var level := _make_level(["GG"])
	level.player_starts = [Vector2i(0, 0)]
	var enemy_entry := LevelUnitSpawnEntry.new()
	enemy_entry.coord = Vector2i(0, 0)
	level.set("enemy_spawns", [enemy_entry])
	var player_row := LevelUnitSpawnEntry.new()
	player_row.level_id = &"demo"
	player_row.slot_index = 0
	player_row.coord = Vector2i(0, 0)
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	var service := LevelAutoFixService.new()
	var report := service.apply(level, &"demo", [], [], [player_row], [], options)
	assert_bool(report != null).is_true()
	assert_int(report.get("applied", []).size()).is_equal(1)
	assert_that(level.player_starts[0]).is_equal(Vector2i(1, 0))

func test_repair_task_metadata_handles_missing_params() -> void:
	var service := LevelAutoFixService.new()
	var level := _make_level(["GG"])
	var objective := Objective.new()
	var stage := Stage.new()
	stage.id = &"test_stage"
	var task := Task.new() # Missing all params
	task.id = &""
	task.title = ""
	task.event_type = ""
	stage.tasks = [task]
	objective.stages = [stage]
	level.objective = objective

	var context := service._build_context(level, &"demo")
	var report := _make_report_stub()
	var options := LevelAutoFixOptions.new()
	options.log_missing_params = true

	service._repair_tasks(level, report, context, options) # This calls _repair_task_metadata internally if options.log_missing_params

	assert_bool(String(task.id).is_empty()).is_false()
	assert_that(String(task.id)).is_equal("task_test_stage_0")
	assert_bool(task.title.is_empty()).is_false()
	assert_that(task.event_type).is_equal("interact")
	assert_int(report["applied"].size()).is_at_least(1)
