extends GdUnitTestSuite

const CheckpointManagerScript = preload("res://Gameplay/turn/checkpoint_manager.gd")

class FakeUnitManager extends UnitManager:
	func create_memento(): return {}
	func restore_from_memento(_c): pass

class FakeTaskManager extends TaskManager:
	func create_memento(): return {}
	func restore_from_memento(_c): pass

class FakeTurnController extends TurnController:
	func create_memento(): return {}
	func restore_from_memento(_c): pass

class FakeHUDController extends HUDController:
	var msg: String = ""
	func show_feedback(m: String) -> void: msg = m

class FakeCameraController extends CameraController:
	var centered: bool = false
	func center_on_selected() -> void: centered = true

class FakeMapController extends MapController:
	func get_grid() -> TileMapLayer: return TileMapLayer.new()
	func get_terrain_map() -> TerrainMap: return TerrainMap.new()

class FakeGridVisuals extends GridVisuals:
	var updated: bool = false
	func update_range_indicator(_g, _u, _m) -> void: updated = true


func test_checkpoint_manager_on_undo_redo_requested() -> void:
	var cm: CheckpointManagerScript = CheckpointManagerScript.new()
	var state = auto_free(GameState.new({}))

	state.hud_controller = auto_free(FakeHUDController.new())
	state.camera_controller = auto_free(FakeCameraController.new())
	state.grid_visuals = auto_free(FakeGridVisuals.new())
	state.map_controller = auto_free(FakeMapController.new())

	# Stub the undo/redo methods to just return true
	# (Actually cm.undo/redo tests the real _history, so let's populate it)


	state.unit_manager = auto_free(FakeUnitManager.new())
	state.task_manager = auto_free(FakeTaskManager.new())
	state.turn_controller = auto_free(FakeTurnController.new())

	cm.setup(state)

	cm.create_checkpoint(state)
	cm.create_checkpoint(state)

	# Request undo
	cm.on_undo_requested()
	assert_str(state.hud_controller.msg).is_equal("Undo")
	assert_bool(state.camera_controller.centered).is_true()
	assert_bool(state.grid_visuals.updated).is_true()

	# Reset
	state.hud_controller.msg = ""
	state.camera_controller.centered = false
	state.grid_visuals.updated = false

	# Request redo
	cm.on_redo_requested()
	assert_str(state.hud_controller.msg).is_equal("Redo")
	assert_bool(state.camera_controller.centered).is_true()
	assert_bool(state.grid_visuals.updated).is_true()

	state.map_controller.get_grid().queue_free()
