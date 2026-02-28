class_name Location
extends Target

signal interacted(unit: Unit)

@export var loc_name: String
@export var description: String
@export var danger: bool = false # When true, exploring costs an action and may require checks

var open :bool=true

var coord: Vector2i

func _ready() -> void:
	# Initialization logic if needed
	pass

func set_grid_coord(grid_coord: Vector2i) -> void:
	coord = grid_coord

func interact(unit: Unit) -> void:
	interacted.emit(unit)
