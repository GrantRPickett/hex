extends GdUnitTestSuite

const LevelRowLoader := preload("res://level/level_row_loader.gd")
const LevelRowValidator := preload("res://level/level_row_validator.gd")
const LevelRosterRow := preload("res://level/level_roster_row.gd")
const LevelLootRow := preload("res://level/level_loot_row.gd")
const LevelTaskRow := preload("res://level/level_task_row.gd")
const LevelTerrainRow := preload("res://level/level_terrain_row.gd")
const LevelAutoFixOptions := preload("res://level/level_auto_fix_options.gd")
const LevelStartRow := preload("res://level/level_start_row.gd")
const LevelDialogueRow := preload("res://level/level_dialogue_row.gd")
const LevelMetaRow := preload("res://level/level_meta_row.gd")
const LevelAutoFixService := preload("res://level/level_auto_fix_service.gd")
const Level := preload("res://level/Level.gd")
const LevelTerrainData := preload("res://level/level_terrain_data.gd")
const LevelLootEntry := preload("res://level/level_loot_entry.gd")

class DummyValidator extends LevelRowValidator:
	var called_with: Array = []

	func validate(level, level_id, roster_rows, loot_rows, location_rows, terrain_rows, start_rows, dialogue_rows, meta_rows, had_existing_loot):
		called_with = [level, level_id, roster_rows, loot_rows, location_rows, terrain_rows, start_rows, dialogue_rows, meta_rows, had_existing_loot]
		return ["stub-error"]

class DummyAutoFixService extends LevelAutoFixService:
	var apply_args: Array = []

	func apply(level, level_id, roster_rows, location_rows, start_rows, options):
		apply_args = [level, level_id, roster_rows, location_rows, start_rows, options]
		return {"applied": ["stub"]}

func _create_level() -> Level:
	var level := Level.new()
	if level.terrain_data == null:
		level.terrain_data = LevelTerrainData.new()
	level.terrain_data.grid_width = 10
	level.terrain_data.grid_height = 10
	var rows: Array[String] = []
	for _i in range(level.terrain_data.grid_height):
		rows.append("G".repeat(level.terrain_data.grid_width))
	level.terrain_data.terrain_rows = rows
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
	roster_row.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var loot_row := LevelLootRow.new()
	loot_row.level_id = level_id
	loot_row.coord = Vector2i(2, 2)
	loot_row.items = [load("res://Resources/items/bronze_grit.tres")]
	var location_row := LevelTaskRow.new()
	location_row.level_id = level_id
	location_row.coord = Vector2i(3, 3)
	location_row.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	var start_row := LevelStartRow.new()
	start_row.level_id = level_id
	start_row.faction = &"player"
	start_row.slot_index = 0
	start_row.coord = Vector2i(0, 0)
	var neutral_start := LevelStartRow.new()
	neutral_start.level_id = level_id
	neutral_start.faction = &"neutral"
	neutral_start.slot_index = 0
	neutral_start.coord = Vector2i(2, 0)
	neutral_start.unit_scene = load("res://Gameplay/scene_templates/generic_unit.tscn")
	var enemy_start := LevelStartRow.new()
	enemy_start.level_id = level_id
	enemy_start.faction = &"enemy"
	enemy_start.slot_index = 0
	enemy_start.coord = Vector2i(3, 0)
	enemy_start.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var dialogue_row := LevelDialogueRow.new()
	dialogue_row.level_id = level_id
	dialogue_row.entry_id = &"intro"
	dialogue_row.coord = Vector2i(1, 0)
	dialogue_row.dialogue_resource_path = "res://Resources/level_data/dialogue_rows/example_dialogue.dialogue"
	var meta_row := LevelMetaRow.new()
	meta_row.level_id = level_id
	meta_row.hex_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	loader.set_row_sources([roster_row], [loot_row], [location_row], _make_terrain_rows(level_id), [start_row, neutral_start, enemy_start], [dialogue_row], [meta_row])

	var level := _create_level()
	var result := loader.apply_rows_to_level(level, level_id)
	var errors: Array = result.get("errors", [])

	assert_array(errors).is_empty()
	assert_object(level.enemy_roster_definition).is_not_null()
	assert_int(level.enemy_roster_definition.spawn_entries.size()).is_equal(1)
	assert_that(level.enemy_roster_definition.spawn_entries[0].coord).is_equal(Vector2i(1, 2))
	assert_object(level.loot).is_not_null()
	assert_int(level.loot.size()).is_equal(1)
	assert_that(level.loot[0].coord).is_equal(Vector2i(2, 2))
	assert_int(level.locations.size()).is_equal(1)
	assert_that(level.locations[0].coord).is_equal(Vector2i(3, 3))
	assert_that(level.player_starts.size()).is_equal(1)
	assert_that(level.player_starts[0]).is_equal(Vector2i(0, 0))
	var neutral_spawns: Array = level.get("neutral_spawns")
	assert_bool(neutral_spawns != null).is_true()
	assert_int(neutral_spawns.size()).is_equal(1)
	assert_that(neutral_spawns[0].coord).is_equal(neutral_start.coord)
	var enemy_spawns: Array = level.get("enemy_spawns")
	assert_bool(enemy_spawns != null).is_true()
	assert_int(enemy_spawns.size()).is_equal(1)
	assert_that(enemy_spawns[0].coord).is_equal(enemy_start.coord)
	assert_that(level.dialogue_entries.size()).is_equal(1)
	assert_that(level.dialogue_entries[0].dialogue_resource_path).is_equal("res://Resources/level_data/dialogue_rows/example_dialogue.dialogue")
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
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate roster coordinate"))).is_true()

func test_out_of_bounds_location_reported() -> void:
	var loader := LevelRowLoader.new()
	var location_row := LevelTaskRow.new()
	location_row.level_id = &"demo"
	location_row.coord = Vector2i(99, 99)
	location_row.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	loader.set_row_sources([], [], [location_row], _make_terrain_rows(&"demo"))

	var level := _create_level()
	level.terrain_data.grid_width = 4
	level.terrain_data.grid_height = 4
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

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
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate start coordinate"))).is_true()

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
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate start coordinate"))).is_true()

func test_dialogue_missing_timeline_reported() -> void:
	var loader := LevelRowLoader.new()
	var dialogue_row := LevelDialogueRow.new()
	dialogue_row.level_id = &"demo"
	dialogue_row.entry_id = &"missing"
	dialogue_row.coord = Vector2i(0, 0)
	dialogue_row.dialogue_resource_path = ""
	loader.set_row_sources([], [], [], _make_terrain_rows(&"demo"), [], [dialogue_row])

	var level := _create_level()
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("missing dialogue resource"))).is_true()

func test_auto_fix_moves_location_from_impassable_tile() -> void:
	var loader := LevelRowLoader.new()
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	loader.set_auto_fix_options(options)
	var location_row := LevelTaskRow.new()
	location_row.level_id = &"demo"
	location_row.coord = Vector2i(0, 0)
	location_row.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	loader.set_row_sources([], [], [location_row], _make_terrain_rows(&"demo"))

	var level := _create_level()
	level.terrain_data.grid_width = 2
	level.terrain_data.grid_height = 1
	level.terrain_data.terrain_rows = ["WG"]
	var result := loader.apply_rows_to_level(level, &"demo")
	var report: Dictionary = result.get("auto_fix")
	assert_bool(report != null).is_true()
	assert_that(level.locations[0].coord).is_equal(Vector2i(1, 0))
	assert_int(report.get("applied", []).size()).is_equal(1)

func test_rows_for_level_returns_keyed_arrays() -> void:
	var loader := LevelRowLoader.new()
	var level_id := &"demo"
	var roster_row := LevelRosterRow.new()
	roster_row.level_id = level_id
	roster_row.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var loot_row := LevelLootRow.new()
	loot_row.level_id = level_id
	loot_row.coord = Vector2i(2, 0)
	loot_row.items = [load("res://Resources/items/bronze_grit.tres")]
	var location_row := LevelTaskRow.new()
	location_row.level_id = level_id
	location_row.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	var start_row := LevelStartRow.new()
	start_row.level_id = level_id
	start_row.coord = Vector2i(0, 0)
	var dialogue_row := LevelDialogueRow.new()
	dialogue_row.level_id = level_id
	dialogue_row.entry_id = &"intro"
	dialogue_row.dialogue_resource_path = "res://Resources/level_data/dialogue_rows/example_dialogue.dialogue"
	var meta_row := LevelMetaRow.new()
	meta_row.level_id = level_id
	loader.set_row_sources([roster_row], [loot_row], [location_row], _make_terrain_rows(level_id), [start_row], [dialogue_row], [meta_row])

	var rows := loader._rows_for_level(String(level_id))
	assert_array(rows["roster"]).contains(roster_row)
	assert_array(rows["loot"]).contains(loot_row)
	assert_array(rows["locations"]).contains(location_row)
	assert_array(rows["terrain"]).has_size(2)
	assert_array(rows["start"]).contains(start_row)
	assert_array(rows["dialogue"]).contains(dialogue_row)
	assert_array(rows["meta"]).contains(meta_row)

func test_apply_combat_rows_updates_level_and_reports_existing_loot() -> void:
	var loader := LevelRowLoader.new()
	var level := _create_level()
	level.loot = []
	var existing_entry := LevelLootEntry.new()
	existing_entry.coord = Vector2i(5, 5)
	level.loot = [existing_entry]
	var roster_row := LevelRosterRow.new()
	roster_row.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var loot_row := LevelLootRow.new()
	loot_row.items = [load("res://Resources/items/bronze_grit.tres")]
	var location_row := LevelTaskRow.new()
	location_row.location_scene = load("res://Gameplay/scene_templates/location.tscn")

	var had_existing := loader._apply_combat_rows(level, [roster_row], [loot_row], [location_row])

	assert_bool(had_existing).is_true()
	assert_object(level.enemy_roster_definition).is_not_null()
	assert_int(level.loot.size()).is_equal(1)
	assert_that(level.locations[0].location_scene).is_equal(location_row.location_scene)

func test_validate_and_autofix_uses_validator_and_service() -> void:
	var loader := LevelRowLoader.new()
	loader._validator = DummyValidator.new()
	var options := LevelAutoFixOptions.new()
	options.enabled = true
	options.write_report = false
	loader.set_auto_fix_options(options)
	loader._auto_fix_service = DummyAutoFixService.new()
	var level := _create_level()
	var roster_rows: Array = []
	var location_rows: Array = []
	var start_rows: Array = []
	var rows := {
		"roster": roster_rows,
		"loot": [],
		"locations": location_rows,
		"terrain": [],
		"start": start_rows,
		"dialogue": [],
		"meta": [],
	}

	var result := loader._validate_and_autofix(level, &"demo", rows, false)

	assert_that(result.get("errors")).is_equal(["stub-error"])
	assert_bool(result.has("auto_fix")).is_true()
	assert_that(loader._validator.called_with[1]).is_equal(&"demo")
	assert_that(loader._auto_fix_service.apply_args[2]).is_same_as(roster_rows)
	assert_that(loader._auto_fix_service.apply_args[3]).is_same_as(location_rows)
