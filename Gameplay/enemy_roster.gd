class_name EnemyRoster
extends Resource

@export var enemy_types: Array[PackedScene] = []

func get_enemy_scene(index: int) -> PackedScene:
	if index >= 0 and index < enemy_types.size():
		return enemy_types[index]
	return null

func get_random_enemy_scene() -> PackedScene:
	if enemy_types.is_empty():
		return null
	return enemy_types.pick_random()