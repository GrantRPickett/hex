extends GdUnitTestSuite

# Test coverage for menu callback functions

const CREDITS_SCENE := "res://Menus/credits.tscn"
const TITLE_SCENE := "res://Menus/title_screen.tscn"

func test_credits_set_return_delay() -> void:
	var runner := scene_runner(CREDITS_SCENE)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	assert_that(scene).is_not_null()

	# Test setting custom delays
	var delay1 := 0.5
	scene.set_return_delay(delay1)
	await runner.simulate_frames(1)
	assert_that(scene.return_delay).is_equal(delay1)

	var delay2 := 2.0
	scene.set_return_delay(delay2)
	await runner.simulate_frames(1)
	assert_that(scene.return_delay).is_equal(delay2)

func test_title_screen_set_quit_callback() -> void:
	var runner := scene_runner(TITLE_SCENE)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	assert_that(scene).is_not_null()

	# Create a test callback
	var was_called := false
	var test_callback = func():
		was_called = true

	# Set the callback
	scene.set_quit_callback(test_callback)
	await runner.simulate_frames(1)

	# Verify callback was stored (access private member for test verification)
	assert_that(scene._quit_callback.is_null()).is_false()
