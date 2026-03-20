extends GdUnitTestSuite

# Tests for global spawning in LevelContentSpawner.

const LevelContentSpawnerScript := preload("res://level/level_content_spawner.gd")
const LevelScript := preload("res://level/level.gd")
const LevelBuildContextScript := preload("res://level/level_build_context.gd")
const LevelTaskEntryScript := preload("res://level/level_task_entry.gd")

var _context: LevelBuildContext
var _spawner: LevelContentSpawner

func before_test() -> void:
    var mock_unit_manager = auto_free(mock(UnitManager))
    var mock_task_manager = auto_free(mock(TaskManager))
    var mock_loot_manager = auto_free(mock(LootManager))
    var mock_grid = auto_free(mock(Node2D))
    
    # Setup mock grid
    do_return(Vector2.ZERO).on(mock_grid).map_to_local(any_vector2i())
    
    _context = auto_free(LevelBuildContextScript.new(
        null, null, mock_unit_manager, null, mock_task_manager, mock_loot_manager, 
        null, mock_grid, null, null, null, null, null, [], null, true, null, null, "Scout", null
    ))
    _spawner = LevelContentSpawnerScript.new(_context, null)

func after_test() -> void:
    for child in get_children():
        if is_instance_valid(child):
            child.queue_free()

func test_spawn_global_content_spawns_locations() -> void:
    var level = auto_free(LevelScript.new())
    var entry = auto_free(LevelTaskEntryScript.new())
    entry.coord = Vector2i(5, 5)
    entry.id = "TestLoc"
    level.locations = [entry]
    
    _spawner.spawn_global_content(level)
    
    # Verify TaskManager received the registration call
    verify(_context.task_manager).register_location(any_node())

func test_spawn_global_content_spawns_loot() -> void:
    var level = auto_free(LevelScript.new())
    var entry = auto_free(LevelTaskEntryScript.new())
    entry.coord = Vector2i(6, 6)
    entry.id = "TestLoot"
    level.loot = [entry]
    
    _spawner.spawn_global_content(level)
    
    # Verify TaskManager received registration
    verify(_context.task_manager).register_loot(any_node())
    # Verify LootManager received the spawn call (via TargetSpawner)
    verify(_context.loot_manager).spawn_loot_at(any_vector2i(), any_node())
