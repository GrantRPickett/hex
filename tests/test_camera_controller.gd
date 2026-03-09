extends GdUnitTestSuite

const CameraControllerScript = preload("res://Gameplay/camera_controller.gd")

func test_toggle_free_cam() -> void:
	var controller = CameraControllerScript.new()
	var mock_handler = Node.new()
	mock_handler.set_script(preload("res://Gameplay/camera_handler.gd"))
	
	controller._camera_handler = mock_handler
	
	assert_bool(mock_handler.is_free_cam()).is_false()
	controller.toggle_free_cam()
	assert_bool(mock_handler.is_free_cam()).is_true()
	controller.toggle_free_cam()
	assert_bool(mock_handler.is_free_cam()).is_false()
	
	mock_handler.free()
	controller.free()
