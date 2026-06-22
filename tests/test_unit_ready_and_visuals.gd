extends GdUnitTestSuite

const UNIT_SCENE := preload("res://Gameplay/targets/unit.gd")


func test__ready_connects_core_signals() -> void:
	var unit := _spawn_unit()
	unit._ready()

	assert_bool(unit.willpower_changed.is_connected(unit._on_willpower_changed)).is_true()
	assert_bool(unit.attribute_modifiers_changed.is_connected(unit._sync_max_willpower)).is_true()
	assert_bool(unit.attribute_modifiers_changed.is_connected(unit._invalidate_attribute_cache)).is_true()
	assert_bool(unit.aid_buffs_changed.is_connected(unit._on_aid_buffs_changed_for_cache)).is_true()


func test__ready_configures_action_resource_consumers() -> void:
	var unit := _spawn_unit()
	unit._ready()

	assert_bool(is_instance_valid(unit.res)).is_true()
	assert_bool(unit.res.action_consumed.is_connected(unit.consume_aid_buffs)).is_true()


func test_update_visuals_assigns_neutral_region_from_spawn_index() -> void:
	var unit := _spawn_unit()
	unit.faction = GameConstants.Faction.NEUTRAL
	unit.loyalty_type = GameConstants.Faction.STATIC
	unit.spawn_index = 7
	unit.master_texture = _make_visual_test_texture(6, 8)
	unit._ready()

	unit.update_visuals()

	var sprite: Sprite2D = unit.get_node("Sprite2D")
	var region := sprite.region_rect
	assert_vector2(region.position).is_equal(Vector2(32, 192)) # Row 7 (index 6), column 2 (index 1)
	assert_vector2(region.size).is_equal(Vector2(32, 32))
	assert_color(sprite.modulate).is_equal(GameColors.YELLOW)


func _spawn_unit() -> Unit:
	var unit: Unit = auto_free(UNIT_SCENE.new())
	get_tree().root.add_child(unit)
	return unit


func _make_visual_test_texture(columns: int, rows: int) -> Texture2D:
	var image := Image.create(columns * 32, rows * 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
