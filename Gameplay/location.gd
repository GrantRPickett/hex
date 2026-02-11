class_name Location
extends Resource

@export var name: String
@export var description: String
@export var coordinates: Array[Vector2i]

var units_present: Array[Unit] = []
var inhabited: bool = false
var tasks: Array[Task] = []

func _ready() -> void:
    # Initialize any necessary data or state here
    pass