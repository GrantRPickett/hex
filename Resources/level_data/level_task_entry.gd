class_name LevelTaskEntry
extends Resource

@export var coord: Vector2i
@export var location_scene: PackedScene # Reference to a location .tscn file

func get_location_scene() -> PackedScene:
	return location_scene

func get_coord() -> Vector2i:
	return coord
