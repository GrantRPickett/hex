extends GdUnitTestSuite

func _simulate_mouse_click(scene: Node, position: Vector2, button_index: int, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = position
	ev.global_position = position # For consistency, often same as position in 2D or local to viewport
	ev.button_index = button_index
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _simulate_frames(runner: GdUnitSceneRunner, frames: int = 1) -> void:
	await runner.simulate_frames(frames)

func _create_scene_runner(scene_path: String) -> GdUnitSceneRunner:
	return scene_runner(scene_path)
