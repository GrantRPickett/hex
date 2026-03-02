class_name LevelUnitSpawnEntry
extends Resource

@export var coord: Vector2i
@export var unit_scene: PackedScene # Reference to a Unit .tscn file
@export var inventory: Array[InventoryItem] = []
@export var ai_profile: CombatPriorityProfile
@export var faction: int = -1 # Default to -1 to use spawner default or override

@export_group("Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 10

func get_unit_scene() -> PackedScene:
	return unit_scene

func get_coord() -> Vector2i:
	return coord

func get_inventory() -> Array[InventoryItem]:
	return inventory

func get_ai_profile() -> CombatPriorityProfile:
	return ai_profile
