class_name LevelLocationEntry
extends Resource

@export var level_id: StringName = &""
@export var id: String = ""
@export var stage_id: String = ""
@export var notes: String = ""
@export var is_narrative: bool = false
@export var description: String = ""
@export var loyalty: GameConstants.Faction = GameConstants.Faction.NEUTRAL
@export var coord: Vector2i = GameConstants.INVALID_COORD
@export var location_scene: PackedScene
@export var location_name: String = ""
@export var location_icon: Texture2D
@export var stats: CombatStats
@export var inhabited: bool = false
@export var attributes: Dictionary = {}

func get_coord() -> Vector2i:
	return coord

func get_location_scene() -> PackedScene:
	return location_scene

func get_stats() -> CombatStats:
	return stats