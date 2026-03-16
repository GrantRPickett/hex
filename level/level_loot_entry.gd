class_name LevelLootEntry
extends Resource

@export var level_id: StringName = &""
@export var id: String = ""
@export var notes: String = ""
@export var coord: Vector2i = Vector2i.ZERO

@export var items: Array[InventoryItem] # Array of InventoryItem Resources
@export var is_trapped: bool = false

@export var stats: CombatStats

func get_items() -> Array[InventoryItem]:
	return items

func get_coord() -> Vector2i:
	return coord

func get_stats() -> CombatStats:
	return stats
