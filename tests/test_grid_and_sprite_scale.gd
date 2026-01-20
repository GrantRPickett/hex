extends "res://addons/gdUnit4/api/GDUGTest.gd"
class_name TestGridAndSpriteScale

var grid_controller_script = preload("res://Gameplay/grid_controller.gd")
var generic_unit_scene = preload("res://Gameplay/generic_unit.tscn")
var generic_enemy_scene = preload("res://Gameplay/generic_enemy.tscn")
var goal_scene = preload("res://Gameplay/goal.tscn")

func test_grid_tile_size_is_96x96():
	var grid_node = TileMap.new()
	var grid_controller = grid_controller_script.new()
	grid_controller.setup(grid_node)
	grid_controller.configure_tileset()
	assert_eq(Vector2i(96, 96), grid_node.tile_set.tile_size, "Tile size should be 96x96")

func test_generic_unit_sprite_scale_is_0_5():
	var unit_instance = generic_unit_scene.instantiate()
	var sprite = unit_instance.find_child("Sprite2D")
	assert_not_null(sprite, "Unit should have a Sprite2D child")
	assert_eq(Vector2(0.5, 0.5), sprite.scale, "Sprite scale should be 0.5, 0.5")
	unit_instance.free()

func test_generic_enemy_sprite_scale_is_0_5():
	var enemy_instance = generic_enemy_scene.instantiate()
	var sprite = enemy_instance.find_child("Sprite2D")
	assert_not_null(sprite, "Enemy should have a Sprite2D child")
	assert_eq(Vector2(0.5, 0.5), sprite.scale, "Sprite scale should be 0.5, 0.5")
	enemy_instance.free()

func test_goal_sprite_scale_is_0_5():
	var goal_instance = goal_scene.instantiate()
	var sprite = goal_instance.find_child("Sprite2D")
	assert_not_null(sprite, "Goal should have a Sprite2D child")
	assert_eq(Vector2(0.5, 0.5), sprite.scale, "Sprite scale should be 0.5, 0.5")
	goal_instance.free()