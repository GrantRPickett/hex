extends GdUnitTestSuite

# Tests for GameObjectiveController: get_target_task, create_target_texture

const ControllerScript := preload("res://Gameplay/narrative/task/game_objective_controller.gd")

class FakeTaskManager extends TaskManager:
	func get_task_by_id(id: String) -> Task:
		if id == "found":
			var t = Task.new()
			t.id = "found"
			return t
		return null

func test_get_target_task_delegates_to_task_manager() -> void:
	var ctrl := ControllerScript.new()
	var mgr: TaskManager = auto_free(FakeTaskManager.new())
	ctrl.setup(mgr, auto_free(UnitManager.new()))

	var t1 = ctrl.get_target_task("found")
	assert_object(t1).is_not_null()
	assert_str(t1.id).is_equal("found")

	var t2 = ctrl.get_target_task("missing")
	assert_object(t2).is_null()

func test_create_target_texture_returns_image_texture() -> void:
	var ctrl := ControllerScript.new()
	var tex = ctrl.create_target_texture(Color.RED, Color.GREEN)
	assert_object(tex).is_not_null()
	assert_bool(tex is ImageTexture).is_true()
	assert_int(tex.get_width()).is_equal(64)
	assert_int(tex.get_height()).is_equal(64)
