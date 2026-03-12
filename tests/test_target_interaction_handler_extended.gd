extends GdUnitTestSuite

const HandlerClass = preload("res://Gameplay/targets/components/target_interaction_handler.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_explore() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())
	unit.set_task_manager(tm)
	
	var task = auto_free(Task.new())
	task.target_coord = Vector2i(0, 0)

	var handler = HandlerClass.new(unit)
	handler.set_unit_manager(um)
	handler.set_task_manager(tm)
	
	var result = handler.explore(task)
	assert_bool(result).is_false() # Should be false as it's a stub/empty setup

func test_visit_location() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())

	var loc = auto_free(Location.new())

	var handler = HandlerClass.new(unit)
	handler.set_unit_manager(um)

	# Will probably return failure since no scene setup, but verifies it doesn't crash on signature call
	var result = handler.visit_location(loc)
	assert_bool(result).is_true() # Base implementation returns true after interact()

func test_convince_unit() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())
	var target = auto_free(Stubs.FakeUnit.new())

	var handler = HandlerClass.new(unit)
	handler.set_unit_manager(um)

	var result = handler.convince_unit(target)
	assert_bool(result).is_true()
