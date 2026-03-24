class_name Location
extends Target

signal exploration_state_changed(new_state: ExplorationState)

enum ExplorationState {
	EXPLORABLE,
	EXPLORED
}

@export var loc_name: String
@export var description: String
@export var loyalty: GameConstants.Faction = GameConstants.Faction.NEUTRAL
@export var danger: bool = false # When true, exploring costs an action and may require checks
@export var location_icon: Texture2D
@export var open_door_texture: Texture2D
@export var closed_door_texture: Texture2D

@export_group("State")
@export var exploration_state: ExplorationState = ExplorationState.EXPLORABLE:
	set(value):
		if exploration_state != value:
			exploration_state = value
			exploration_state_changed.emit(exploration_state)
			update_visuals()

# TODO: Determine if exploration state should be tracked per faction or globally.
var open: bool = true

var coord: Vector2i
var _task_manager: TaskManager

func _ready() -> void:
	# Initialize base_willpower for exploration if it was default Target value
	if base_willpower == 1:
		base_willpower = 10
	z_index = GameConstants.ZIndex.LOCATION

	_ensure_sprite_setup()
	update_visuals()

func _ensure_sprite_setup() -> void:
	if not is_instance_valid(sprite):
		sprite = get_node_or_null("Sprite2D")

	if not is_instance_valid(sprite):
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	if sprite is Sprite2D:
		# Godot 4: Force the tileset texture if using placeholder or null to ensure region-based swapping works.
		var current_path: String = ""
		if sprite.texture:
			current_path = sprite.texture.resource_path

		var tileset_path := "res://Resources/art/placeholder/32rogues/tiles.png"
		if current_path == "" or current_path.find("chest.png") != -1 or current_path.find("tiles.png") == -1:
			sprite.texture = load(tileset_path)

		# Now enable region based on the tileset
		sprite.region_enabled = true
		if "scale" in sprite:
			sprite.scale = Vector2(2, 2) # Reset scale if it was 2x for the sliced version
		sprite.centered = true

func set_task_manager(tm: TaskManager) -> void:
	if _task_manager != tm:
		_task_manager = tm
		if _task_manager:
			if not _task_manager.task_updated.is_connected(_on_task_event):
				_task_manager.task_updated.connect(_on_task_event)
			if not _task_manager.task_completed.is_connected(_on_task_event_unit):
				_task_manager.task_completed.connect(_on_task_event_unit)
			if not _task_manager.objective_updated.is_connected(_on_objective_updated):
				_task_manager.objective_updated.connect(_on_objective_updated)
		update_visuals()

func _on_task_event(_idx: int, _faction: int) -> void:
	update_visuals()

func _on_task_event_unit(_idx: int, _faction: int, _unit: Unit) -> void:
	update_visuals()

func _on_objective_updated(_objective: Objective) -> void:
	update_visuals()

func update_visuals() -> void:
	if not is_instance_valid(sprite):
		return

	var has_task := false
	if _task_manager:
		var tasks = _task_manager.get_active_tasks_for_target(self )
		has_task = not tasks.is_empty()

	if sprite.region_enabled:
		# Use 32rogues coordinates
		# 17.c = (2, 16) * 32 = (64, 512) -> shut
		# 17.d = (3, 16) * 32 = (96, 512) -> open
		if exploration_state == ExplorationState.EXPLORED or has_task:
			sprite.region_rect = Rect2(96, 512, 32, 32)
		else:
			sprite.region_rect = Rect2(64, 512, 32, 32)
	elif open_door_texture and closed_door_texture:
		sprite.texture = open_door_texture if has_task else closed_door_texture

func set_grid_coord(grid_coord: Vector2i) -> void:
	coord = grid_coord
	set_external_grid_coord(grid_coord)


func mark_explored() -> void:
	exploration_state = ExplorationState.EXPLORED
