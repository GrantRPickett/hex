extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func _wheel(scene: Node, button: int, pressed := true, lmb := false, rmb := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	# Apply button state modifiers via direct mouse handler
	if lmb:
		var lb := InputEventMouseButton.new()
		lb.button_index = MOUSE_BUTTON_LEFT
		lb.pressed = true
		scene._handle_mouse_button(lb)
	if rmb:
		var rb := InputEventMouseButton.new()
		rb.button_index = MOUSE_BUTTON_RIGHT
		rb.pressed = true
		scene._handle_mouse_button(rb)
	scene._handle_mouse_button(ev)

func _click(scene: Node, button: int, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.pressed = true
	scene._handle_mouse_button(ev)

func test_camera_centers_on_selected_and_mouse_inputs_work() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var cam: Camera2D = scene.get_node("Camera2D")
	var p1: Node2D = scene.get_node("Player")
	var p2: Node2D = scene.get_node("Player2")

	# Starts centered on P1
	assert_that(cam.position).is_equal(p1.position)

	# Cycle selection via internal helper and center should change to P2
	scene._cycle_selection(1)
	await runner.simulate_frames(1)
	assert_that(cam.position).is_equal(p2.position)

	# Mouse wheel zoom (no buttons)
	var start_zoom := cam.zoom.x
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	scene._handle_mouse_button(wheel)
	await runner.simulate_frames(1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	# Rotation with RMB + wheel (simulate RMB being down, then wheel)
	var start_rot := cam.rotation
	var rmb_down := InputEventMouseButton.new()
	rmb_down.button_index = MOUSE_BUTTON_RIGHT
	rmb_down.pressed = true
	scene._handle_mouse_button(rmb_down)
	var wheel_with_rmb := InputEventMouseButton.new()
	wheel_with_rmb.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_with_rmb.pressed = true
	scene._handle_mouse_button(wheel_with_rmb)
	await runner.simulate_frames(1)
	assert_that(cam.rotation).is_not_equal(start_rot)

	# Unit selection and movement via direct request_move (InputEvents don't work in headless)
	var p1_click_pos: Vector2 = p1.get_global_transform_with_canvas().origin
	var lmb_click := InputEventMouseButton.new()
	lmb_click.button_index = MOUSE_BUTTON_LEFT
	lmb_click.position = p1_click_pos
	lmb_click.pressed = true
	scene._handle_mouse_button(lmb_click)
	await runner.simulate_frames(1)
	assert_that(cam.position).is_equal(p1.position)

	# Direct move request instead of relying on mouse clicks
	var from: Vector2i = scene.player_coord
	var dir_map: Dictionary = scene._direction_map(from)
	# Pick the first available direction that stays in bounds
	var picked := ""
	var target_cell: Vector2i = Vector2i.ZERO
	for k in dir_map.keys():
		target_cell = from + dir_map[k]
		# Check if in bounds (grid is 7x7)
		if target_cell.x >= 0 and target_cell.y >= 0 and target_cell.x < 7 and target_cell.y < 7:
			picked = k
			break
	assert_that(picked).is_not_empty()
	scene.request_move(picked)
	await runner.simulate_frames(1)
	assert_that(scene.player_coord).is_equal(target_cell)

