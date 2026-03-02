class_name LevelTaskEntry
extends Resource

@export var coord: Vector2i
@export var location_scene: PackedScene # Reference to a location .tscn file

@export_group("Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 10

func get_location_scene() -> PackedScene:
	return location_scene

func get_coord() -> Vector2i:
	return coord
