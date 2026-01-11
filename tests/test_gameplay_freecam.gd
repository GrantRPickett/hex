
extends  "res://tests/test_utils.gd"
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
    var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
    var scene := runner.scene()
    _simulate_frames(runner, 1)

    var handler := scene.get_node("CameraHandler")
    assert_that(handler).is_not_null()
    var cam := handler.get_node(handler.camera_node) as Camera2D
    assert_that(cam).is_not_null()
    var start_center := cam.position

    # Toggle free cam via keyboard (~)
    _press_key(scene, KEY_QUOTELEFT)
    _simulate_frames(runner, 1)

    # Move unit; camera should not re-center in free cam
    scene.set_player_coord(Vector2i(1, 1))
    _simulate_frames(runner, 1)
    var start_coord: Vector2i = scene.player_coord
    scene.request_move("move_w")
    _simulate_frames(runner, 1)
    assert_that(scene.player_coord).is_not_equal(start_coord)
    assert_that(cam.position).is_equal(start_center)

    # Connect to the handler's signal to know when to check for re-centering
    var re_centered = false
    handler.free_cam_toggled.connect(func(is_free):
        if not is_free: # This block is executed when free cam is turned OFF
            _simulate_frames(runner, 1) # allow gameplay to process it
            assert_that(cam.position).is_equal(scene.get_node("Player").position)
            re_centered = true
    )

    # Toggle back via middle-click; camera should re-center
    _click_middle(scene)
    _simulate_frames(runner, 1)
    assert_that(re_centered).is_true()
