extends Resource
class_name LevelRosterRow

@export var level_id: StringName = &""
@export var faction: StringName = &"enemy"
@export var coord: Vector2i = Vector2i.ZERO
@export var unit_scene: PackedScene
@export var notes: String = ""
@export var ai_profile: CombatPriorityProfile

@export_group("Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 10
