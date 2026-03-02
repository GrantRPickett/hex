extends Resource
class_name LevelLootRow

@export var level_id: StringName = &""
@export var coord: Vector2i = Vector2i.ZERO
@export var items: Array[Resource] = []
@export var notes: String = ""
@export var is_trapped: bool = false

@export_group("Trap Attributes")
@export var grit: int = 6
@export var flow: int = 6
@export var gusto: int = 6
@export var focus: int = 6
@export var shine: int = 6
@export var shade: int = 6
@export var willpower: int = 1
