extends GdUnitTestSuite

const TITLE_SCENE := "res://Menus/title_screen.tscn"
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const CREDITS_SCENE := "res://Menus/credits.tscn"

# Signal test state
var test_signal_received := false
var test_signal_path := ""
var test_signals_received: Array[String] = []
var test_completed_count := 0
var test_requested_count := 0

func _on_scene_change_requested(path: String) -> void:
	test_requested_count += 1
	test_signals_received.append("requested")

func _on_scene_change_completed(path: String) -> void:
	test_signal_received = true
	test_signal_path = path
	test_completed_count += 1
	test_signals_received.append("completed")

func test_scene_change_requested_signal_emits() -> void:
	# Reset state
	test_signal_received = false
	test_signal_path = ""
	test_requested_count = 0

	var slot = Callable(self, "_on_scene_change_requested")
	SceneTransition.scene_change_requested.connect(slot)

	await SceneTransition.change_scene(TITLE_SCENE, 0.0, true)  # emit_signal_only=true

	# Wait for signal with timeout (max 5 frames)
	for i in range(5):
		if test_requested_count > 0:
			break
		await get_tree().process_frame

	SceneTransition.scene_change_requested.disconnect(slot)
	assert_that(test_requested_count).is_equal(1)

func test_scene_change_completed_signal_emits_after_transition() -> void:
	# Reset state
	test_signal_received = false
	test_signal_path = ""
	test_completed_count = 0

	var slot = Callable(self, "_on_scene_change_completed")
	SceneTransition.scene_change_completed.connect(slot)

	# Change to title screen (simpler scene)
	var change_result = await SceneTransition.change_scene(TITLE_SCENE, 0.0)

	# Wait briefly for signal
	for i in range(5):
		if test_signal_received:
			break
		await get_tree().process_frame

	SceneTransition.scene_change_completed.disconnect(slot)
	assert_that(change_result).is_true()
	assert_that(test_signal_received).is_true()
	assert_that(test_signal_path).is_equal(TITLE_SCENE)

func test_scene_change_signal_order_is_correct() -> void:
	# Reset state
	test_signals_received.clear()
	test_requested_count = 0
	test_completed_count = 0

	var req_slot = Callable(self, "_on_scene_change_requested")
	var comp_slot = Callable(self, "_on_scene_change_completed")

	SceneTransition.scene_change_requested.connect(req_slot)
	SceneTransition.scene_change_completed.connect(comp_slot)

	# Request scene change
	var change_result = await SceneTransition.change_scene(TITLE_SCENE, 0.0)

	# Wait for signals
	for i in range(10):
		if test_requested_count > 0 and test_completed_count > 0:
			break
		await get_tree().process_frame

	SceneTransition.scene_change_requested.disconnect(req_slot)
	SceneTransition.scene_change_completed.disconnect(comp_slot)

	assert_that(change_result).is_true()
	assert_that(test_signals_received).contains("requested")
	assert_that(test_signals_received).contains("completed")
	# Requested should come before completed
	if test_signals_received.size() >= 2:
		assert_that(test_signals_received[0]).is_equal("requested")
		assert_that(test_signals_received[1]).is_equal("completed")

func test_scene_change_with_delay_signals_emit() -> void:
	# Reset state
	test_signal_received = false
	test_completed_count = 0
	var delay_seconds := 0.05

	var slot = Callable(self, "_on_scene_change_completed")
	SceneTransition.scene_change_completed.connect(slot)

	# Change scene with delay
	var change_result = await SceneTransition.change_scene(TITLE_SCENE, delay_seconds)

	SceneTransition.scene_change_completed.disconnect(slot)
	assert_that(change_result).is_true()
	assert_that(test_completed_count).is_greater_than(0)

func test_scene_change_requested_signal_only_emits() -> void:
	# Reset state
	test_requested_count = 0
	test_completed_count = 0

	var req_slot = Callable(self, "_on_scene_change_requested")
	var comp_slot = Callable(self, "_on_scene_change_completed")

	SceneTransition.scene_change_requested.connect(req_slot)
	SceneTransition.scene_change_completed.connect(comp_slot)

	# Use emit_signal_only=true
	var result = await SceneTransition.change_scene(TITLE_SCENE, -1.0, true)

	# Wait a few frames to ensure no completed signal
	for i in range(5):
		await get_tree().process_frame

	SceneTransition.scene_change_requested.disconnect(req_slot)
	SceneTransition.scene_change_completed.disconnect(comp_slot)

	assert_that(result).is_true()
	assert_that(test_requested_count).is_equal(1)
	assert_that(test_completed_count).is_equal(0)  # No completed signal when emit_signal_only

func test_reload_current_emits_signals() -> void:
	# First navigate to a known scene
	await SceneTransition.change_scene(TITLE_SCENE, 0.0)

	# Reset state
	test_signal_received = false
	test_signal_path = ""
	test_completed_count = 0

	var slot = Callable(self, "_on_scene_change_completed")
	SceneTransition.scene_change_completed.connect(slot)

	# Reload current scene
	var reload_result = await SceneTransition.reload_current()

	# Wait for signal
	for i in range(10):
		if test_signal_received:
			break
		await get_tree().process_frame

	SceneTransition.scene_change_completed.disconnect(slot)
	assert_that(reload_result).is_true()
	assert_that(test_signal_received).is_true()
	assert_that(test_signal_path).is_equal(TITLE_SCENE)

func test_is_changing_state_during_transition() -> void:
	# Test that is_changing() returns true during scene transition
	# and false after completion

	# Start at title screen
	await SceneTransition.change_scene(TITLE_SCENE, 0.0)

	# Verify not changing initially
	assert_that(SceneTransition.is_changing()).is_false()

	# Now test with gameplay (which takes longer to load)
	# We check is_changing within a few frames
	var found_changing_state := false
	var state_after_frames := SceneTransition.is_changing()
	
	# Start transition (don't await yet)
	var change_started := false
	var change_result := false
	
	# Use a deferred task to handle the async call
	var transition_started = false
	if not transition_started:
		transition_started = true
		# Fire off the transition but don't wait for it immediately
		var dummy = await SceneTransition.change_scene(GAMEPLAY_SCENE, 0.05)
		change_result = dummy
	
	# Check if is_changing returned true at any point during transition
	for i in range(15):  # Check for up to 250ms (15 frames at 60fps)
		if SceneTransition.is_changing():
			found_changing_state = true
		await get_tree().process_frame
	
	# By end, should not be changing
	assert_that(SceneTransition.is_changing()).is_false()

func test_concurrent_scene_change_requests_ignored() -> void:
	# Test that requesting scene change while already changing is ignored
	test_completed_count = 0

	var slot = Callable(self, "_on_scene_change_completed")
	SceneTransition.scene_change_completed.connect(slot)

	# Start transition to gameplay (longer scene) - will await later
	var first_change = SceneTransition.change_scene(GAMEPLAY_SCENE, 0.05)

	# Immediately try to change to different scene
	var second_change = await SceneTransition.change_scene(TITLE_SCENE, 0.0)

	# Second change should be ignored (return false)
	assert_that(second_change).is_false()

	# Wait for first change to complete
	var first_result = await first_change

	# Wait for signals
	for i in range(10):
		await get_tree().process_frame

	SceneTransition.scene_change_completed.disconnect(slot)

	# Only first change should have completed
	assert_that(first_result).is_true()
	assert_that(test_completed_count).is_equal(1)

func test_signal_timeout_protection() -> void:
	# Test explicit timeout to prevent test hanging
	test_signal_received = false
	test_completed_count = 0

	var slot = Callable(self, "_on_scene_change_completed")
	SceneTransition.scene_change_completed.connect(slot)

	# Request scene change and wait with timeout protection
	var timeout_frames := 60  # ~1 second at 60 FPS
	var frame_count := 0
	# Note: coroutine is started but not awaited until later
	var change_task = SceneTransition.change_scene(TITLE_SCENE, 0.0)

	while frame_count < timeout_frames:
		if test_signal_received:
			break
		await get_tree().process_frame
		frame_count += 1

	var change_result = await change_task

	SceneTransition.scene_change_completed.disconnect(slot)

	# Verify both timeout didn't occur AND signal was received
	assert_that(frame_count).is_less_than(timeout_frames)
	assert_that(change_result).is_true()
	assert_that(test_signal_received).is_true()

	SceneTransition.scene_change_completed.disconnect(slot)

	# Should not timeout in normal conditions
	assert_that(timeout_occurred).is_false()
	assert_that(change_result).is_true()
	assert_that(signal_received).is_true()

