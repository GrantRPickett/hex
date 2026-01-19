extends GdUnitTestSuite

var _loot_manager: LootManager

func before() -> void:
	_loot_manager = auto_free(LootManager.new())

func before_test() -> void:
	# Clear any loot from previous tests
	if _loot_manager:
		_loot_manager.reset()
		# Free all loot items that were created
		for loot in _loot_manager.get_all_loot():
			if is_instance_valid(loot):
				loot.queue_free()
		_loot_manager.reset()

func test_add_loot() -> void:
	var loot = auto_free(Loot.new())
	var coord = Vector2i(1, 1)

	_loot_manager.add_loot(loot, coord)

	assert_int(_loot_manager.get_loot_count()).is_equal(1)
	assert_object(_loot_manager.get_loot_at(coord)).is_equal(loot)

func test_add_loot_null() -> void:
	var initial_count = _loot_manager.get_loot_count()

	_loot_manager.add_loot(null, Vector2i(1, 1))

	assert_int(_loot_manager.get_loot_count()).is_equal(initial_count)

func test_remove_loot() -> void:
	var loot = auto_free(Loot.new())
	var coord = Vector2i(1, 1)
	_loot_manager.add_loot(loot, coord)

	_loot_manager.remove_loot(loot)

	assert_int(_loot_manager.get_loot_count()).is_equal(0)
	assert_object(_loot_manager.get_loot_at(coord)).is_null()

func test_remove_non_existent_loot() -> void:
	var loot = auto_free(Loot.new())
	var initial_count = _loot_manager.get_loot_count()

	_loot_manager.remove_loot(loot)

	assert_int(_loot_manager.get_loot_count()).is_equal(initial_count)

func test_get_loot_at() -> void:
	var loot1 = auto_free(Loot.new())
	var loot2 = auto_free(Loot.new())
	_loot_manager.add_loot(loot1, Vector2i(1, 1))
	_loot_manager.add_loot(loot2, Vector2i(2, 2))

	assert_object(_loot_manager.get_loot_at(Vector2i(1, 1))).is_equal(loot1)
	assert_object(_loot_manager.get_loot_at(Vector2i(2, 2))).is_equal(loot2)
	assert_object(_loot_manager.get_loot_at(Vector2i(3, 3))).is_null()

func test_has_loot_at() -> void:
	var loot = auto_free(Loot.new())
	_loot_manager.add_loot(loot, Vector2i(1, 1))

	assert_bool(_loot_manager.has_loot_at(Vector2i(1, 1))).is_true()
	assert_bool(_loot_manager.has_loot_at(Vector2i(2, 2))).is_false()

func test_get_loot_count() -> void:
	assert_int(_loot_manager.get_loot_count()).is_equal(0)

	var loot1 = auto_free(Loot.new())
	var loot2 = auto_free(Loot.new())
	_loot_manager.add_loot(loot1, Vector2i(1, 1))
	_loot_manager.add_loot(loot2, Vector2i(2, 2))

	assert_int(_loot_manager.get_loot_count()).is_equal(2)

func test_get_loot() -> void:
	var loot1 = auto_free(Loot.new())
	var loot2 = auto_free(Loot.new())
	_loot_manager.add_loot(loot1, Vector2i(1, 1))
	_loot_manager.add_loot(loot2, Vector2i(2, 2))

	assert_object(_loot_manager.get_loot(0)).is_equal(loot1)
	assert_object(_loot_manager.get_loot(1)).is_equal(loot2)
	assert_object(_loot_manager.get_loot(2)).is_null()

func test_get_all_loot() -> void:
	var loot1 = auto_free(Loot.new())
	var loot2 = auto_free(Loot.new())
	_loot_manager.add_loot(loot1, Vector2i(1, 1))
	_loot_manager.add_loot(loot2, Vector2i(2, 2))

	var all_loot = _loot_manager.get_all_loot()

	assert_int(all_loot.size()).is_equal(2)
	assert_bool(all_loot.has(loot1)).is_true()
	assert_bool(all_loot.has(loot2)).is_true()

func test_spawn_loot_empty_items() -> void:
	_loot_manager.spawn_loot(Vector2i(1, 1), [])

	assert_int(_loot_manager.get_loot_count()).is_equal(0)

func test_spawn_loot_new_loot() -> void:
	var item = auto_free(InventoryItem.new())

	_loot_manager.spawn_loot(Vector2i(1, 1), [item])

	assert_int(_loot_manager.get_loot_count()).is_equal(1)
	var spawned_loot = _loot_manager.get_loot_at(Vector2i(1, 1))
	assert_object(spawned_loot).is_not_null()

func test_spawn_loot_to_existing() -> void:
	var item1 = auto_free(InventoryItem.new())
	var item2 = auto_free(InventoryItem.new())

	_loot_manager.spawn_loot(Vector2i(1, 1), [item1])
	_loot_manager.spawn_loot(Vector2i(1, 1), [item2])

	assert_int(_loot_manager.get_loot_count()).is_equal(1)
