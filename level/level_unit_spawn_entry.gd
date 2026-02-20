class_name LevelUnitSpawnEntry
extends Resource

@export var coord: Vector2i
@export var unit_scene: PackedScene # Reference to a Unit .tscn file
@export var inventory: Array[InventoryItem] = []

func get_unit_scene() -> PackedScene:
	return unit_scene

func get_coord() -> Vector2i:
	return coord

func get_inventory() -> Array[InventoryItem]:
	return inventory
