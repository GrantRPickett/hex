extends GdUnitTestSuite

const ManagerScript := preload("res://level/level_manager_gameplay.gd")
const LevelBuilderClass = preload("res://level/level_builder.gd")
const LevelBuildContextClass = preload("res://level/level_build_context.gd")
const LevelClass = preload("res://level/Level.gd")
const LevelTerrainDataClass = preload("res://level/level_terrain_data.gd")
const UnitManagerClass = preload("res://Gameplay/targets/unit_manager.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

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

	# Pass empty level path should fail gently
	var result = mgr.prepare_level_data("")
	assert_bool(result).is_false()

func test_clear_world() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	mgr.clear_world(lvl)
	# Should print debug and pass

func test_build_environment() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	lvl.terrain_data = auto_free(LevelTerrainData.new())
	var tm = auto_free(Stubs.FakeTerrainMap.new())

	var context = auto_free(LevelBuildContextClass.new(null, auto_free(Node.new()), auto_free(UnitManagerClass.new()), null, null, null, null, auto_free(Node.new()), auto_free(Camera2D.new()), null, null, null, null, [], lvl, true, null, null, "", null))
	mgr._level_builder = auto_free(LevelBuilderClass.new(context))

	mgr.build_environment(lvl, tm)

func test_spawn_global_content() -> void:
	var mgr := _make_manager()
	var lvl = auto_free(Level.new())
	var tm = auto_free(Stubs.FakeTerrainMap.new())

	var context = auto_free(LevelBuildContextClass.new(null, auto_free(Node.new()), auto_free(UnitManagerClass.new()), null, null, null, null, auto_free(Node.new()), auto_free(Camera2D.new()), null, null, null, null, [], lvl, true, null, null, "", null))
	mgr._level_builder = auto_free(LevelBuilderClass.new(context))

	mgr.spawn_global_content(lvl, tm)
