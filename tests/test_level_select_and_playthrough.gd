#extends GdUnitTestSuite
#
#const TITLE_SCENE := "res://Menus/title_screen.tscn"
#const LEVEL_SELECT_SCENE := "res://Menus/level_select.tscn"
#const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
#const LEVEL1_PATH := "res://Resources/levels/level1.tres"
#const LEVEL2_PATH := "res://Resources/levels/level2.tres"
#
#
#func _level_display_name(path: String) -> String:
	#var name := path.get_file()
	#var res: Resource = load(path)
	#if res and res.has_method("get"):
		#var display: Variant = res.get("display_name")
		#if typeof(display) == TYPE_STRING and display != "":
			#name = display
	#return name
#
#func _bfs_actions(scene: Node, start: Vector2i, location: Vector2i) -> Array:
	#var dir_map: Dictionary = scene._direction_map(start)
	#var neighbors := func (c: Vector2i) -> Array:
		#var out: Array = []
		#var dm: Dictionary = scene._direction_map(c)
		#for a in dm.keys():
			#var nc: Vector2i = c + dm[a]
			#if scene._is_within_bounds(nc):
				#out.append([nc, a])
		#return out
	#var q: Array = []
	#var came_from: Dictionary = {}
	#q.append(start)
	#came_from[start] = null
	#var action_from: Dictionary = {}
	#while q.size() > 0:
		#var cur: Vector2i = q.pop_front()
		#if cur == location:
			#break
		#for pair in neighbors.call(cur):
			#var nc: Vector2i = pair[0]
			#var act: String = pair[1]
			#if not came_from.has(nc):
				#came_from[nc] = cur
				#action_from[nc] = act
				#q.append(nc)
	#if not came_from.has(location):
		#return []
	#var path_actions: Array = []
	#var c := location
	#while c != start:
		#path_actions.push_front(action_from[c])
		#c = came_from[c]
	#return path_actions
#
#func _play_level_with_ai(level_path: String) -> void:
	#if Engine.has_singleton("LevelManager"):
		#LevelManager.set_current_level_path(level_path)
	#var runner := scene_runner(GAMEPLAY_SCENE)
	#var scene := runner.scene()
	#await runner.simulate_frames(1)
#
	## Determine if dual-target mode is active via available second location sprite position
	#var dual: bool = is_instance_valid(scene.get_node_or_null("location2")) and scene._use_dual_locations
#
	#if dual:
		## Unit 0 -> location1
		#var a1 := _bfs_actions(scene, scene.player_coord, scene.location_coord)
		#for a in a1:
			#scene._selected_index = 0
			#scene.request_move(a)
			#await runner.simulate_frames(1)
		## Unit 1 -> location2
		#var a2 := _bfs_actions(scene, scene._player_coords[1], scene.location2_coord)
		#for a in a2:
			#scene._selected_index = 1
			#scene.request_move(a)
			#await runner.simulate_frames(1)
		#await runner.simulate_frames(2)
	#else:
		#var a := _bfs_actions(scene, scene.player_coord, scene.location_coord)
		#for act in a:
			#scene._selected_index = 0
			#scene.request_move(act)
			#await runner.simulate_frames(1)
		#await runner.simulate_frames(2)
#
#func test_level_select_uses_level_manager_listing() -> void:
	#if not Engine.has_singleton("LevelManager"):
		#return
#
	#LevelManager.set_levels([LEVEL2_PATH, LEVEL1_PATH])
	#LevelManager.set_current_level_path("")
#
	#var runner := scene_runner(LEVEL_SELECT_SCENE)
	#var scene := runner.scene()
	#await runner.simulate_frames(1)
#
	#var list := scene.get_node("Panel/VBox/List") as VBoxContainer
	#assert_that(list.get_child_count()).is_greater(0)
#
	#var mapping: Dictionary = {}
	#for path in LevelManager.levels:
		#mapping[_level_display_name(path)] = path
#
	#var button := list.get_child(0) as Button
	#assert_that(button).is_not_null()
	#var expected_path := String(mapping.get(button.text, ""))
	#assert_that(expected_path).is_not_empty()
#
	#button.pressed.emit()
	#await runner.simulate_frames(2)
#
	#var active := String(LevelManager.get_current_level_path())
	#assert_that(active).is_equal(expected_path)
	#var current := scene.get_tree().current_scene
	#assert_that(current.scene_file_path).is_equal(GAMEPLAY_SCENE)
#
	#LevelManager.set_levels([])
	#LevelManager.set_current_level_path("")
#
#func test_title_to_level_select_and_pick_level1() -> void:
	#var runner := scene_runner(TITLE_SCENE)
	#var scene := runner.scene()
	#await runner.simulate_frames(1)
#
	## Click Level Select
	#var btn := scene.get_node("Center/VBox/LevelSelectButton") as Button
	#btn.pressed.emit()
	#await runner.simulate_frames(2)
#
	#var current := scene.get_tree().current_scene
	#assert_that(current.scene_file_path).is_equal(LEVEL_SELECT_SCENE)
#
#func test_playthrough_all_levels_with_ai() -> void:
	## Skip in headless CI where full playthroughs may hang or be timing-sensitive
	#if OS.has_feature("headless"):
		#return
	## Discover levels
	#var dir := DirAccess.open("res://Resources/levels")
	#var level_paths := []
	#for f in dir.get_files():
		#if f.ends_with(".tres"):
			#level_paths.append("res://Resources/levels/" + f)
	#assert_that(level_paths.size()).is_greater(0)
	## Play each level end-to-end
	#for path in level_paths:
		#await _play_level_with_ai(path)
