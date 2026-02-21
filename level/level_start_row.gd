
extends Resource
class_name LevelStartRow

@export var level_id: StringName = StringName("")
@export var faction: StringName = &"player"
@export var slot_index: int = 0
@export var coord: Vector2i = Vector2i.ZERO
@export var unit_scene: PackedScene
@export var notes: String = ""
