class_name LevelUnitSpawnEntry
extends Resource

@export var level_id: StringName = &""
@export var notes: String = ""
@export var coord: Vector2i = Vector2i.ZERO
@export var unit_name: String = "" # Descriptor for logging/validation

@export var faction: int = -1 # Default to -1 to use spawner default or override
@export var slot_index: int = 0
@export var unit_scene: PackedScene # Reference to a Unit .tscn file
@export var inventory: Array[InventoryItem] = []
@export var ai_profile: CombatPriorityProfile
@export var loyalty_type: GameConstants.Loyalty.Type = GameConstants.Loyalty.Type.NEUTRAL

@export var stats: CombatStats


func get_unit_scene() -> PackedScene:
	return unit_scene

func get_coord() -> Vector2i:
	return coord

func get_inventory() -> Array[InventoryItem]:
	return inventory

func get_ai_profile() -> CombatPriorityProfile:
	return ai_profile

func get_stats() -> CombatStats:
	return stats
