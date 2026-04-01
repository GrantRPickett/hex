class_name Location
extends Target

@export var loc_name: String
@export var description: String
@export var loyalty: GameConstants.Faction = GameConstants.Faction.NEUTRAL
@export var danger: bool = false # When true, exploring costs an action and may require checks
@export var claimer_faction: GameConstants.Faction = GameConstants.Faction.NEUTRAL
@export var location_icon: Texture2D
@export var open_door_texture: Texture2D
@export var closed_door_texture: Texture2D

@export_group("State")
@export var is_explored: bool = false:
	set(value):
		if is_explored != value:
			is_explored = value
			update_visuals()

var coord: Vector2i
var _task_manager: TaskManager

func _ready() -> void:
	super()
	is_opposed = danger
	display_as_task = true
	# Default willpower initialization
	if base_willpower == 1:
		base_willpower = 10
	z_index = GameConstants.ZIndex.LOCATION

	_ensure_sprite_setup()
	update_visuals()

func get_interaction_type() -> String:
	return GameConstants.Activity.EXPLORE if is_opposed else GameConstants.Activity.VISIT

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

	var _has_task := false
	if _task_manager:
		var tasks = _task_manager.get_active_tasks_for_target(self)
		_has_task = not tasks.is_empty()

	if sprite.region_enabled:
		if is_explored:
			sprite.region_rect = Rect2(160, 512, 32, 32) # Door 2 Open (17f)
		else:
			sprite.region_rect = Rect2(128, 512, 32, 32) # Door 2 Closed (17e)

	sprite.modulate = GameColors.get_faction_color(claimer_faction)

func get_attribute_by_index(idx: GameConstants.AttributeIndex) -> int:
	match idx:
		GameConstants.AttributeIndex.GRIT: return grit
		GameConstants.AttributeIndex.FLOW: return flow
		GameConstants.AttributeIndex.GUSTO: return gusto
		GameConstants.AttributeIndex.FOCUS: return focus
		GameConstants.AttributeIndex.SHINE: return shine
		GameConstants.AttributeIndex.SHADE: return shade
	return 0

func interact(unit: Unit, context: Dictionary = {}) -> void:
	interacted.emit(unit, context, self)

func is_all_revealed() -> bool:
	return is_explored

func mark_explored() -> void:
	is_explored = true


func get_current_willpower() -> int:
	return willpower

func get_max_willpower() -> int:
	return base_willpower

func get_target_name() -> String:
	return loc_name

func get_target_id() -> String:
	return id

func _get_subtype_prefix() -> String:
	return get_script().get_global_name().to_lower()
