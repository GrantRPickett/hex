extends GdUnitTestSuite

func test_reset_inputs_to_defaults_restores_settings() -> void:
    var original_move := ControlSettings.move_actions.duplicate(true)
    var original_cam := ControlSettings.camera_actions.duplicate(true)
    var original_sel := ControlSettings.selection_actions.duplicate(true)
    var original_pause := ControlSettings.pause_actions.duplicate(true)

    ControlSettings.move_actions = [{"action": "move_d", "keys": [KEY_F8], "joy_buttons": []}]
    ControlSettings.camera_actions = []
    ControlSettings.selection_actions = []
    ControlSettings.pause_actions = []

    ControlSettings.reset_inputs_to_defaults()

    assert_that(ControlSettings.move_actions).is_not_equal([{"action": "move_d", "keys": [KEY_F8], "joy_buttons": []}])
    assert_that(ControlSettings.camera_actions).is_not_equal([])
    assert_that(ControlSettings.selection_actions).is_not_equal([])
    assert_that(ControlSettings.pause_actions).is_not_equal([])

    # Restore original to avoid side effects
    ControlSettings.move_actions = original_move
    ControlSettings.camera_actions = original_cam
    ControlSettings.selection_actions = original_sel
    ControlSettings.pause_actions = original_pause

