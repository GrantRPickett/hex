extends GdUnitTestSuite

const CheckpointManagerScript = preload("res://Gameplay/turn/checkpoint_manager.gd")

class MockManager extends Node:
	func create_memento(): return {}
	func restore_from_memento(_c): pass

class FakeHUDController extends Node:
	var msg = ""
	func show_feedback(m: String) -> void: msg = m

class FakeCameraController extends Node:
	var centered = false
	func center_on_selected() -> void: centered = true

class FakeMapController extends Node:
	func get_grid() -> TileMapLayer: return TileMapLayer.new()
	func get_terrain_map() -> Dictionary: return {}

class FakeGridVisuals extends Node:
	var updated = false
	func update_range_indicator(_g, _u, _m) -> void: updated = true


func test_checkpoint_manager_on_undo_redo_requested() -> void:
	var cm = CheckpointManagerScript.new()
	var state = auto_free(GameState.new({}))

	state.hud_controller = auto_free(FakeHUDController.new())
	state.camera_controller = auto_free(FakeCameraController.new())
	state.grid_visuals = auto_free(FakeGridVisuals.new())
	state.map_controller = auto_free(FakeMapController.new())

	# Stub the undo/redo methods to just return true
	# (Actually cm.undo/redo tests the real _history, so let's populate it)


	state.unit_manager = auto_free(MockManager.new())
	state.task_manager = auto_free(MockManager.new())
	state.turn_controller = auto_free(MockManager.new())

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
