extends Resource
class_name LevelTaskRow

@export var level_id: StringName = &""
@export var coord: Vector2i = Vector2i.ZERO
@export var location_scene: PackedScene
@export var notes: String = ""

@export_group("Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 10
