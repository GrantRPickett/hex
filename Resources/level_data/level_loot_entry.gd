class_name LevelLootEntry
extends Resource

@export var coord: Vector2i
@export var items: Array[Resource] # Array of InventoryItem Resources

func get_items() -> Array[Resource]:
	return items

func get_coord() -> Vector2i:
	return coord
