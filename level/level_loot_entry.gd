class_name LevelLootEntry
extends Resource

@export var level_id: StringName = &""
@export var notes: String = ""
@export var coord: Vector2i = Vector2i.ZERO

@export var items: Array[Resource] # Array of InventoryItem Resources
@export var is_trapped: bool = false

@export var stats: CombatStats

func get_items() -> Array[Resource]:
	return items

func get_coord() -> Vector2i:
	return coord

func get_stats() -> CombatStats:
	if not stats:
		stats = CombatStats.new()
	return stats
