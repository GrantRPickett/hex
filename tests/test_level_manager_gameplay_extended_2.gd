extends GdUnitTestSuite

# FORCE_IMPORT_TIMESTAMP: 2026-03-11 16:00:00

const ManagerScript := preload("res://level/level_manager_gameplay.gd")
const LevelBuilderClass = preload("res://level/level_builder.gd")
const LevelBuildContextClass = preload("res://level/level_build_context.gd")
const LevelClass = preload("res://level/Level.gd")
const LevelTerrainDataClass = preload("res://level/level_terrain_data.gd")
const UnitManagerClass = preload("res://Gameplay/targets/unit_manager.gd")

func _make_manager() -> LevelManagerGameplay:
	var state := GameState.new({})
	return auto_free(ManagerScript.new(state, auto_free(Node.new())))

func test_set_save_manager() -> void:
	var mgr := _make_manager()
	var sm = auto_free(Node.new())
	mgr.set_save_manager(sm)
	assert_object(mgr._save_manager).is_equal(sm)

func test_set_auto_fix_enabled() -> void:
	var mgr := _make_manager()
	mgr.set_auto_fix_enabled(true)
	assert_bool(mgr._auto_fix_enabled).is_true()

func test_prepare_level_data() -> void:
	var mgr := _make_manager()

	# Level resource needs to be set for prepare_level_data to work
	var lvl = auto_free(Level.new())
	mgr.set_level_resource(lvl)
	mgr.prepare_level_data()
	# Should not crash

func test_clear_world() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	mgr.set_level_resource(lvl)
	mgr.clear_world()
	# Should print debug and pass

func test_build_environment() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	lvl.terrain_data = auto_free(LevelTerrainDataClass.new())

	# We need to mock level builder if it's used internally
	# However, LevelManagerGameplay creates it internally in build_environment()
	# The parse error was about build_environment(lvl, terrain_map) but it now takes 0 args.
	
	mgr.set_level_resource(lvl)
	mgr.build_environment()

func test_spawn_global_content() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	
	mgr.set_level_resource(lvl)
	mgr.spawn_global_content()
