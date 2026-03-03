extends GdUnitTestSuite

const GenericUnit := preload("res://Gameplay/scene_templates/generic_unit.tscn")
const GenericEnemy := preload("res://Gameplay/scene_templates/generic_enemy.tscn")
const locationScene := preload("res://Gameplay/scene_templates/location.tscn")

func _assert_equal(actual, expected, message: String) -> void:
	assert_that(actual).override_failure_message(message).is_equal(expected)

func _assert_not_null(value, message: String) -> void:
	assert_that(value).override_failure_message(message).is_not_null()

func test_grid_tile_size_is_96x96() -> void:
	var grid_node := TileMap.new()
	var grid_controller: GridController = GridController.new()
	grid_controller.setup(grid_node)
	grid_controller.configure_tileset()
	_assert_equal(grid_node.tile_set.tile_size, Vector2i(96, 96), "Tile size should be 96x96")

func test_generic_unit_sprite_scale_is_0_5() -> void:
	var unit_instance: Node2D = GenericUnit.instantiate()
	var sprite := unit_instance.find_child("Sprite2D")
	_assert_not_null(sprite, "Unit should have a Sprite2D child")
	_assert_equal(sprite.scale, Vector2(0.5, 0.5), "Sprite scale should be 0.5, 0.5")
	unit_instance.queue_free()

func test_generic_enemy_sprite_scale_is_0_5() -> void:
	var enemy_instance: Node2D = GenericEnemy.instantiate()
	var sprite := enemy_instance.find_child("Sprite2D")
	_assert_not_null(sprite, "Enemy should have a Sprite2D child")
	_assert_equal(sprite.scale, Vector2(0.5, 0.5), "Sprite scale should be 0.5, 0.5")
	enemy_instance.queue_free()

func test_location_sprite_scale_is_0_5() -> void:
	var location_instance: Node2D = locationScene.instantiate()
	var sprite := location_instance.find_child("Sprite2D")
	_assert_not_null(sprite, "location should have a Sprite2D child")
	_assert_equal(sprite.scale, Vector2(0.5, 0.5), "Sprite scale should be 0.5, 0.5")
	location_instance.queue_free()
