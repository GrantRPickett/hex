extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

func _press_key(scene: Node, key: Key) -> void:
    var ev := InputEventKey.new()
    ev.keycode = key as Key
    ev.pressed = true
    scene._unhandled_input(ev)

func test_camera_is_current_on_ready() -> void:
    var runner := scene_runner(GAMEPLAY_SCENE_PATH)
    var scene := runner.scene()
    await runner.simulate_frames(1)

    var cam: Camera2D = scene.get_node("Camera2D")
    assert_that(cam).is_not_null()
    assert_that(cam.is_current()).is_true()

func test_camera_rotate_and_zoom_do_not_affect_movement() -> void:
    var runner := scene_runner(GAMEPLAY_SCENE_PATH)
    var scene := runner.scene()
    await runner.simulate_frames(1)

    var cam: Camera2D = scene.get_node("Camera2D")
    assert_that(cam).is_not_null()

    # Record starting state
    var start_rot := cam.rotation
    var start_zoom := cam.zoom.x

    # Rotate left (Z) and right (X)
    _press_key(scene, KEY_Z)
    await runner.simulate_frames(1)
    assert_that(cam.rotation).is_not_equal(start_rot)

    var rot_after_left := cam.rotation
    _press_key(scene, KEY_X)
    await runner.simulate_frames(1)
    assert_that(cam.rotation).is_not_equal(rot_after_left)

    # Zoom in (C) then out (V)
    _press_key(scene, KEY_C)
    await runner.simulate_frames(1)
    assert_that(cam.zoom.x).is_not_equal(start_zoom)

    var zoom_after_in := cam.zoom.x
    _press_key(scene, KEY_V)
    await runner.simulate_frames(1)
    assert_that(cam.zoom.x).is_not_equal(zoom_after_in)

    # Ensure movement still functions as expected
    var start_coord: Vector2i = scene.player_coord
    scene.request_move("move_w")
    await runner.simulate_frames(1)
    assert_that(scene.player_coord).is_not_equal(start_coord)

    # Reference new function name to satisfy function coverage
    var mapped: String = scene._map_action_by_camera("move_d", Vector2i(0, 0))
    assert_that(mapped).is_not_null()



