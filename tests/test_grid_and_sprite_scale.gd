extends GdUnitTestSuite

const GridController := preload("res://Gameplay/grid_controller.gd")
const GenericUnit := preload("res://Gameplay/generic_unit.tscn")
const GenericEnemy := preload("res://Gameplay/generic_enemy.tscn")
const GoalScene := preload("res://Gameplay/goal.tscn")

func _assert_equal(actual, expected, message: String) -> void:
	assert_that(actual).override_failure_message(message).is_equal(expected)

func _assert_not_null(value, message: String) -> void:
	assert_that(value).override_failure_message(message).is_not_null()

func test_grid_tile_size_is_96x96() -> void:
	var grid_node := TileMap.new()
	var grid_controller := GridController.new()
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

func test_goal_sprite_scale_is_0_5() -> void:
	var goal_instance: Node2D = GoalScene.instantiate()
	var sprite := goal_instance.find_child("Sprite2D")
	_assert_not_null(sprite, "Goal should have a Sprite2D child")
	_assert_equal(sprite.scale, Vector2(0.5, 0.5), "Sprite scale should be 0.5, 0.5")
	goal_instance.queue_free()
