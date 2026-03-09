extends GdUnitTestSuite

const HandlerClass = preload("res://Gameplay/targets/components/target_interaction_handler.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_explore() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())
	unit.set_task_manager(tm)

	var handler = HandlerClass.new(unit)
	handler._unit_manager = um
	var result = handler.explore(Vector2i(0, 0))
	assert_object(result).is_not_null()
	assert_bool(result.success).is_true()

func test_visit_location() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())

	var loc = auto_free(Location.new())

	var handler = HandlerClass.new(unit)
	handler._unit_manager = um

	# Will probably return failure since no scene setup, but verifies it doesn't crash on signature call
	var result = handler.visit_location(loc)
	assert_object(result).is_not_null()

func test_convince_unit() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())
	var target = auto_free(Stubs.FakeUnit.new())

	var handler = HandlerClass.new(unit)
	handler._unit_manager = um

	var result = handler.convince_unit(target)
	assert_object(result).is_not_null()
