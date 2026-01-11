extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level1.tres"
const LEVEL2_PATH := "res://Resources/levels/level2.tres"
const CREDITS_SCENE := "res://Menus/credits.tscn"
const SCENE_CHANGE_TIMEOUT_FRAMES := 600

func _vector_to_action(scene: Node, from: Vector2i, delta: Vector2i) -> String:
	var dir_map: Dictionary = scene._direction_map(from)
	for k in dir_map.keys():
		if dir_map[k] == delta:
			return k
	return ""

func _await_scene_change(runner: GdUnitSceneRunner, tree: SceneTree, context: String) -> void:
	var changed := false
	var handler := func (_new_scene: Node) -> void:
		changed = true
	tree.scene_changed.connect(handler)
	var frames := 0
	while not changed and frames < SCENE_CHANGE_TIMEOUT_FRAMES:
		_simulate_frames(runner, 1)
		frames += 1
	if tree.scene_changed.is_connected(handler):
		tree.scene_changed.disconnect(handler)
	assert_that(changed).override_failure_message("Scene change timed out while %s" % context).is_true()

func test_level_chain_from_start_to_credits() -> void:
	if not Engine.has_singleton("LevelManager"):
		return

	# make progression explicit and deterministic
	LevelManager.set_levels([LEVEL1_PATH, LEVEL2_PATH])
	LevelManager.set_current_level_path(LEVEL1_PATH)

	var runner := _create_scene_runner(GAMEPLAY_SCENE)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	# Move unit 0 into goal to finish level1
	var g1: Vector2i = scene.goal_coord as Vector2i
	var from1: Vector2i = g1 + Vector2i(-1, 0)
	if not scene._is_within_bounds(from1):
		from1 = g1 + Vector2i(0, -1)
	scene.set_player_coord(from1)
	scene._selected_index = 0
	var action1 := _vector_to_action(scene, from1, g1 - from1)
	scene.request_move(action1)
	await _await_scene_change(runner, scene.get_tree(), "finishing level1")

	var current := scene.get_tree().current_scene
	assert_that(current).is_not_null()
	# After completing level1, we should be back in gameplay which loads level2
	assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE)
	assert_that(LevelManager.get_current_level_path()).is_equal(LEVEL2_PATH)

	# Now finish level2 and expect credits
	var scene2 := current
	_simulate_frames(runner, 1)
	var g2: Vector2i = scene2.goal_coord as Vector2i
	var from2: Vector2i = g2 + Vector2i(-1, 0)
	if not scene2._is_within_bounds(from2):
		from2 = g2 + Vector2i(0, -1)
	scene2.set_player_coord(from2)
	scene2._selected_index = 0
	var action2 := _vector_to_action(scene2, from2, g2 - from2)
	scene2.request_move(action2)
	await _await_scene_change(runner, scene2.get_tree(), "finishing level2")

	var final := scene2.get_tree().current_scene
	assert_that(final).is_not_null()
	assert_that(final.scene_file_path).is_equal(CREDITS_SCENE)
