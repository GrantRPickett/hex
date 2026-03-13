extends GdUnitTestSuite

const LevelRowLoader := preload("res://level/level_row_loader.gd")
const LevelRowValidator := preload("res://level/level_row_validator.gd")
const LevelAutoFixOptions := preload("res://level/level_auto_fix_options.gd")
const LevelAutoFixService := preload("res://level/level_auto_fix_service.gd")
const Level := preload("res://level/Level.gd")
const LevelTerrainData := preload("res://level/level_terrain_data.gd")
const LevelLootEntry := preload("res://level/level_loot_entry.gd")
const LevelTaskEntry := preload("res://level/level_task_entry.gd")
const LevelUnitSpawnEntry := preload("res://level/level_unit_spawn_entry.gd")
const LevelDialogueEntry := preload("res://level/level_dialogue_entry.gd")

# Inject rows directly into the loader's internal dictionaries for testing
func _inject(loader: LevelRowLoader, level_id: StringName,
		roster: Array = [], loot: Array = [], locations: Array = [],
		starts: Array = [], dialogue: Array = [], journal: Array = []) -> void:
	
	loader._roster_rows_by_level[level_id] = roster
	loader._loot_rows_by_level[level_id] = loot
	loader._location_rows_by_level[level_id] = locations
	loader._start_rows_by_level[level_id] = starts
	loader._dialogue_rows_by_level[level_id] = dialogue
	loader._journal_rows_by_level[level_id] = journal
	loader._meta_rows_by_level[level_id] = [] # Set this to prevent auto-refresh

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

func test_apply_rows_populates_spawns_and_entries() -> void:
	var level_id := &"demo"
	var loader := LevelRowLoader.new()

	var loot_entry := _create_loot_entry(level_id, Vector2i(2, 2), [load("res://Resources/items/bronze_grit.tres")])
	var location_entry := _create_location_entry(level_id, Vector2i(3, 3), load("res://Gameplay/scene_templates/location.tscn"))
	var player_start := _create_unit_spawn_entry(level_id, Vector2i(0, 0), Unit.Faction.PLAYER, 0)
	var neutral_start := _create_unit_spawn_entry(level_id, Vector2i(2, 0), Unit.Faction.NEUTRAL, 0, load("res://Gameplay/scene_templates/generic_unit.tscn"))
	var enemy_start := _create_unit_spawn_entry(level_id, Vector2i(3, 0), Unit.Faction.ENEMY, 0, load("res://Gameplay/scene_templates/generic_enemy.tscn"))
	var dialogue_entry := _create_dialogue_entry(level_id, &"intro", Vector2i(1, 0), "res://Resources/level_data/dialogue_rows/example_dialogue.dialogue")
	var journal_entry := _create_journal_entry(level_id, "intro_journal", "intro")

	_inject(loader, level_id,
		[], [loot_entry], [location_entry],
		[player_start, neutral_start, enemy_start], [dialogue_entry], [journal_entry])

	var level := _create_level()
	var result := loader.apply_rows_to_level(level, level_id)
	var errors: Array = result.get("errors", [])

	assert_array(errors).is_empty()
	_verify_level_entities(level, neutral_start, enemy_start)

func _create_loot_entry(level_id: StringName, coord: Vector2i, items: Array[InventoryItem]) -> LevelLootEntry:
	var entry := LevelLootEntry.new()
	entry.level_id = level_id
	entry.coord = coord
	entry.items = items
	return entry

func _create_location_entry(level_id: StringName, coord: Vector2i, scene: PackedScene) -> LevelTaskEntry:
	var entry := LevelTaskEntry.new()
	entry.level_id = level_id
	entry.coord = coord
	entry.location_scene = scene
	return entry

func _create_unit_spawn_entry(level_id: StringName, coord: Vector2i, faction: int, slot: int, scene: PackedScene = null) -> LevelUnitSpawnEntry:
	var entry := LevelUnitSpawnEntry.new()
	entry.level_id = level_id
	entry.faction = faction
	entry.slot_index = slot
	entry.coord = coord
	entry.unit_scene = scene
	return entry

func _create_dialogue_entry(level_id: StringName, entry_id: StringName, coord: Vector2i, path: String) -> LevelDialogueEntry:
	var entry := LevelDialogueEntry.new()
	entry.level_id = level_id
	entry.entry_id = entry_id
	entry.coord = coord
	entry.dialogue_resource_path = path
	return entry

func _create_journal_entry(level_id: StringName, id: String, related_id: String) -> LevelJournalEntry:
	var entry := LevelJournalEntry.new()
	entry.level_id = level_id
	entry.id = id
	entry.related_id = related_id
	return entry

func _verify_level_entities(level: Level, neutral_start: LevelUnitSpawnEntry, enemy_start: LevelUnitSpawnEntry) -> void:
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
	assert_that(level.dialogue_entries[0].dialogue_resource_path).is_equal(
		"res://Resources/level_data/dialogue_rows/example_dialogue.dialogue")

func test_duplicate_roster_rows_reported() -> void:
	var loader := LevelRowLoader.new()
	var row_a := LevelUnitSpawnEntry.new()
	row_a.level_id = &"demo"
	row_a.coord = Vector2i(1, 1)
	row_a.faction = Unit.Faction.ENEMY
	row_a.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	var row_b := LevelUnitSpawnEntry.new()
	row_b.level_id = &"demo"
	row_b.coord = Vector2i(1, 1)
	row_b.faction = Unit.Faction.ENEMY
	row_b.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")
	_inject(loader, &"demo", [row_a, row_b])

	var level := _create_level()
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate roster coordinate"))).is_true()

func test_out_of_bounds_location_reported() -> void:
	var loader := LevelRowLoader.new()
	var entry := LevelTaskEntry.new()
	entry.level_id = &"demo"
	entry.coord = Vector2i(99, 99)
	entry.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	_inject(loader, &"demo", [], [], [entry])

	var level := _create_level()
	level.terrain_data.grid_width = 4
	level.terrain_data.grid_height = 4
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("out of bounds"))).is_true()

func test_duplicate_start_coordinate_reported() -> void:
	var loader := LevelRowLoader.new()
	var start_a := LevelUnitSpawnEntry.new()
	start_a.level_id = &"demo"
	start_a.coord = Vector2i(0, 0)
	var start_b := LevelUnitSpawnEntry.new()
	start_b.level_id = &"demo"
	start_b.coord = Vector2i(0, 0)
	_inject(loader, &"demo", [], [], [], [start_a, start_b])

	var level := _create_level()
	var result := loader.apply_rows_to_level(level, &"demo")
	var errors: Array = result.get("errors", [])

	assert_bool(errors.is_empty()).is_false()
	assert_that(errors.any(func(e): return String(e).contains("Duplicate start coordinate"))).is_true()

func test_dialogue_missing_timeline_reported() -> void:
	var loader := LevelRowLoader.new()
	var entry := LevelDialogueEntry.new()
	entry.level_id = &"demo"
	entry.entry_id = &"missing"
	entry.coord = Vector2i(0, 0)
	entry.dialogue_resource_path = ""
	_inject(loader, &"demo", [], [], [], [], [entry])

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
	options.log_missing_params = false # Disable metadata fixes for this test
	loader.set_auto_fix_options(options)
	var entry := LevelTaskEntry.new()
	entry.level_id = &"demo"
	entry.coord = Vector2i(0, 0)
	entry.location_scene = load("res://Gameplay/scene_templates/location.tscn")
	_inject(loader, &"demo", [], [], [entry])

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

	var roster_entry := LevelUnitSpawnEntry.new()
	roster_entry.level_id = level_id
	roster_entry.unit_scene = load("res://Gameplay/scene_templates/generic_enemy.tscn")

	var loot_entry := LevelLootEntry.new()
	loot_entry.level_id = level_id
	loot_entry.coord = Vector2i(2, 0)
	loot_entry.items = [load("res://Resources/items/bronze_grit.tres")]

	var location_entry := LevelTaskEntry.new()
	location_entry.level_id = level_id
	location_entry.location_scene = load("res://Gameplay/scene_templates/location.tscn")

	var start_entry := LevelUnitSpawnEntry.new()
	start_entry.level_id = level_id
	start_entry.coord = Vector2i(0, 0)

	var dialogue_entry := LevelDialogueEntry.new()
	dialogue_entry.level_id = level_id
	dialogue_entry.entry_id = &"intro"
	dialogue_entry.dialogue_resource_path = "res://Resources/level_data/dialogue_rows/example_dialogue.dialogue"

	_inject(loader, level_id,
		[roster_entry], [loot_entry], [location_entry],
		[start_entry], [dialogue_entry])

	var rows := loader._rows_for_level(String(level_id))
	assert_array(rows["roster"]).contains(roster_entry)
	assert_array(rows["loot"]).contains(loot_entry)
	assert_array(rows["locations"]).contains(location_entry)
	assert_array(rows["start"]).contains(start_entry)
	assert_array(rows["dialogue"]).contains(dialogue_entry)

func test_apply_rows_to_level_with_null_objective() -> void:
	var level_id := &"null_obj_test"
	var loader := LevelRowLoader.new()
	var level := _create_level()
	level.objective = null # Explicitly null (though it is by default)

	# This should NOT crash
	var result := loader.apply_rows_to_level(level, level_id)
	assert_object(result).is_not_null()
	assert_array(result.get("errors", [])).is_empty()
