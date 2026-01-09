extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func _press_key(scene: Node, key: Key) -> void:
    var ev := InputEventKey.new()
    ev.keycode = key as Key
    ev.pressed = true
    scene._unhandled_input(ev)

func _click_middle(scene: Node) -> void:
    var ev := InputEventMouseButton.new()
    ev.button_index = MOUSE_BUTTON_MIDDLE
    ev.pressed = true
    scene._unhandled_input(ev)

func test_toggle_free_cam_keyboard_and_mouse() -> void:
    var runner := scene_runner(GAMEPLAY_SCENE_PATH)
    var scene := runner.scene()
    await runner.simulate_frames(1)

    var cam: Camera2D = scene.get_node("Camera2D")
    var start_center := cam.position

    # Toggle free cam via keyboard (~)
    _press_key(scene, KEY_QUOTELEFT)
    await runner.simulate_frames(1)

    # Move unit; camera should not re-center in free cam
    # Move unit; ensure valid starting position then request move
    scene.set_player_coord(Vector2i(1, 1))
    await runner.simulate_frames(1)
    var start_coord: Vector2i = scene.player_coord
    scene.request_move("move_w")
    await runner.simulate_frames(1)
    assert_that(scene.player_coord).is_not_equal(start_coord)
    assert_that(cam.position).is_equal(start_center)

    # Toggle back via middle-click; camera should re-center
    _click_middle(scene)
    await runner.simulate_frames(1)
    assert_that(cam.position).is_equal(scene.get_node("Player").position)

