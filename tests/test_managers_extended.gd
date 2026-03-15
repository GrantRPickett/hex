extends GdUnitTestSuite

# Tests for LocationService.get_all_locations_data, UnitController.configure_dependencies
# CheckpointManager.create_checkpoint, undo, redo

func test_location_service_get_all_locations_data() -> void:
	var tm = auto_free(TaskManager.new())
	var svc: LocationService = LocationService.new()
	svc.setup(tm)

	var loc: Location = Location.new()
	loc.loc_name = "test_loc"
	loc.coord = Vector2i(1, 1)
	tm._locations = [loc]

	var data = svc.get_all_locations_data()
	assert_int(data.size()).is_equal(1)
	assert_str(data[0]["name"]).is_equal("test_loc")

	loc.queue_free()

func test_unit_controller_configure_dependencies() -> void:
	var uc = auto_free(UnitController.new())
	var state = auto_free(GameState.new({}))
	var config: Config = GameSessionBuilder.Config.new()
	var grid = auto_free(TileMapLayer.new())
	var loot = auto_free(LootManager.new())

	config.grid = grid
	state.loot_manager = loot

	uc.configure_dependencies(state, config)

	assert_object(uc._grid).is_equal(grid)
	assert_object(uc._loot_manager).is_equal(loot)

# CheckpointManager testing requires mocking a ton of memento outputs.
class MockUnitManager extends Node:
	var m: Dictionary = {}
	func create_memento() -> Dictionary: return m
	func restore_from_memento(_d) -> void: pass

class MockTaskManager extends Node:
	var m: Dictionary = {}
	func create_memento() -> Dictionary: return {"task": true}
	func restore_from_memento(_d) -> void: pass

class MockTurnController extends Node:
	var m: Dictionary = {}
	func create_memento() -> Dictionary: return {"turn": 1}
	func restore_from_memento(_d) -> void: pass

func test_checkpoint_manager_history_and_redo() -> void:
	var cm: CheckpointManager = CheckpointManager.new()
	var state = auto_free(GameState.new({}))
	state.unit_manager = auto_free(MockUnitManager.new())
	state.task_manager = auto_free(MockTaskManager.new())
	state.turn_controller = auto_free(MockTurnController.new())

	cm.setup(state)

	assert_bool(cm.undo(state)).is_false() # Empty
	assert_bool(cm.redo(state)).is_false()

	cm.create_checkpoint(state)
	assert_int(cm._history.size()).is_equal(1)

	cm.create_checkpoint(state)
	assert_int(cm._history.size()).is_equal(2)

	# Undo
	assert_bool(cm.undo(state)).is_true()
	assert_int(cm._history.size()).is_equal(1)
	assert_int(cm._redo_stack.size()).is_equal(1)

	# Redo
	assert_bool(cm.redo(state)).is_true()
	assert_int(cm._history.size()).is_equal(2)
	assert_int(cm._redo_stack.size()).is_equal(0)

	cm.queue_free()
