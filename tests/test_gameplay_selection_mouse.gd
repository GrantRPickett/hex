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
	var grid: TileMapLayer = scene.get_node("Grid")

	# Starts centered on P1
	assert_that(cam.position).is_equal(p1.position)

	# Cycle selection via internal helper and center should change to P2
	scene._cycle_selection(1)
	await runner.simulate_frames(1)
	assert_that(cam.position).is_equal(p2.position)

	# Mouse wheel zoom (no buttons)
	var start_zoom := cam.zoom.x
	_wheel(scene, MOUSE_BUTTON_WHEEL_UP)
	await runner.simulate_frames(1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	# Right-click + wheel rotates
	var start_rot := cam.rotation
	_wheel(scene, MOUSE_BUTTON_WHEEL_UP, false, false, true)
	await runner.simulate_frames(1)
	assert_that(cam.rotation).is_not_equal(start_rot)

	# Left-click unit selection
	var p1_click_pos: Vector2 = p1.get_global_transform_with_canvas().origin
	_click(scene, MOUSE_BUTTON_LEFT, p1_click_pos)
	await runner.simulate_frames(1)
	assert_that(cam.position).is_equal(p1.position)

	# Left-click adjacent cell to move one step
	var from: Vector2i = scene.player_coord
	var dir_map: Dictionary = scene._direction_map(from)
	# Pick the first available direction
	var picked := ""
	for k in dir_map.keys():
		picked = k
		break
	var target_cell: Vector2i = from + dir_map[picked]
	var click_local: Vector2 = grid.map_to_local(target_cell)
	var click_pos: Vector2 = grid.get_global_transform_with_canvas() * click_local
	_click(scene, MOUSE_BUTTON_LEFT, click_pos)
	await runner.simulate_frames(1)
	assert_that(scene.player_coord).is_equal(target_cell)
