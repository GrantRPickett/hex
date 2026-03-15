extends GdUnitTestSuite

const LevelFlowControllerClass = preload("res://level/level_flow_controller.gd")
const LevelCatalogClass = preload("res://level/level_catalog.gd")
const LevelProgressStoreClass = preload("res://level/level_progress_store.gd")

func test_start_level() -> void:
	var ctrl = auto_free(LevelFlowControllerClass.new(LevelCatalogClass.new(), LevelProgressStoreClass.new(null)))
	var res = ctrl.start_level("test_level")
	assert_object(res).is_not_null()
	assert_str(ctrl._current_level_id).is_equal("test_level")

func test_start_first_level() -> void:
	var ctrl = auto_free(LevelFlowControllerClass.new(LevelCatalogClass.new(), LevelProgressStoreClass.new(null)))
	ctrl.start_first_level()
	# The first unlocked level is probably hometown
	assert_str(ctrl._current_level_id).is_equal("hometown")

func test_handle_level_complete() -> void:
	var store: LevelProgressStoreClass = LevelProgressStoreClass.new(null)
	var ctrl = auto_free(LevelFlowControllerClass.new(LevelCatalogClass.new(), store))

	# Empty currently, complete missing level
	ctrl.handle_level_complete()

	ctrl._current_level_id = "hometown"
	ctrl.handle_level_complete()

	# Expecting to change scene, but without transition just changes internal state or prints error
	assert_bool(store.is_level_completed("hometown")).is_true()
	# Has more incomplete levels
	assert_str(ctrl._current_level_id).is_equal("")

func test_handle_quit_to_title() -> void:
	var ctrl = auto_free(LevelFlowControllerClass.new())
	ctrl._current_level_id = "test_level"
	ctrl.handle_quit_to_title()
	assert_str(ctrl._current_level_id).is_equal("")
