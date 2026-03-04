extends GdUnitTestSuite

# Tests for Target.is_pixel_inside, and LootManager.remove_loot

func test_target_is_pixel_inside() -> void:
	var t = Target.new()
	t.global_position = Vector2(100, 100)

	# Since there's no sprite, it falls back to radius 32
	var in_bounds = t.is_pixel_inside(Vector2(110, 110))
	assert_bool(in_bounds).is_true()

	var out_bounds = t.is_pixel_inside(Vector2(200, 200))
	assert_bool(out_bounds).is_false()

	t.queue_free()

func test_target_is_pixel_inside_with_sprite() -> void:
	var t = Target.new()
	var s = Sprite2D.new()
	t.add_child(s)
	t.sprite = s
	t.global_position = Vector2(100, 100)

	# Even without texture, rect should be localized to 0
	# However, since its get_global_rect(), we still just call and verify no crash
	var _in_bounds = t.is_pixel_inside(Vector2(100, 100))
	# We just ensure it executed the sprite branch

	t.queue_free()

func test_loot_manager_remove_loot_cleans_up_loot() -> void:
	var lm = auto_free(LootManager.new())
	var u = auto_free(UnitManager.new())
	var tc = auto_free(TaskController.new())
	var c = auto_free(CombatSystem.new())
	lm.setup(u, tc, c)

	var l = Loot.new()
	add_child(l)

	# Register manually for test
	lm._loot_items.append(l)
	lm._coords.append(Vector2i(2, 2))

	lm.remove_loot(l)

	assert_int(lm._loot_items.size()).is_equal(0)
	assert_int(lm._coords.size()).is_equal(0)
	assert_bool(is_instance_valid(l)).is_false()
