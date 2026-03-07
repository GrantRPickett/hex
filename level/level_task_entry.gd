class_name LevelTaskEntry
extends Resource

@export var level_id: StringName = &""
@export var notes: String = ""
@export var coord: Vector2i = Vector2i.ZERO

@export var location_scene: PackedScene # Reference to a location .tscn file
@export var location_name: String = ""
@export var description: String = ""
@export var loyalty: GameConstants.Loyalty.Type = GameConstants.Loyalty.Type.NEUTRAL


@export var stats: CombatStats

func get_location_scene() -> PackedScene:
	return location_scene

func get_coord() -> Vector2i:
	return coord

func get_stats() -> CombatStats:
	return stats
