class_name Location
extends Target

signal interacted(unit: Unit)
signal exploration_state_changed(new_state: ExplorationState)

enum ExplorationState {
	EXPLORABLE,
	EXPLORED
}

@export var loc_name: String
@export var description: String
@export var danger: bool = false # When true, exploring costs an action and may require checks

@export_group("State")
@export var exploration_state: ExplorationState = ExplorationState.EXPLORABLE:
	set(value):
		if exploration_state != value:
			exploration_state = value
			exploration_state_changed.emit(exploration_state)

# TODO: Determine if exploration state should be tracked per faction or globally.
var open :bool=true

var coord: Vector2i

func _ready() -> void:
	# Initialize base_willpower for exploration if it was default Target value
	if base_willpower == 1:
		base_willpower = 10
	pass

func set_grid_coord(grid_coord: Vector2i) -> void:
	coord = grid_coord
	set_external_grid_coord(grid_coord)

func interact(unit: Unit) -> void:
	interacted.emit(unit)

func mark_explored() -> void:
	exploration_state = ExplorationState.EXPLORED
