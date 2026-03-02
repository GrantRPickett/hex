class_name LevelLootEntry
extends Resource

@export var coord: Vector2i
@export var items: Array[Resource] # Array of InventoryItem Resources
@export var is_trapped: bool = false

@export_group("Trap Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 1

func get_items() -> Array[Resource]:
	return items

func get_coord() -> Vector2i:
	return coord
