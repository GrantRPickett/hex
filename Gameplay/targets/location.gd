class_name Location
extends Target

@export var loc_name: String
@export var description: String
@export var boosts: Array[GameConstants.Faction] = []
@export var hazard: bool = false # When true, exploring costs an action and may require checks

@export var location_icon: Texture2D

@export_group("Aura")
@export var aura_coords: Array[Vector2i] = []
@export var aura_attribute: GameConstants.AttributeIndex = GameConstants.AttributeIndex.GRIT
@export var aura_value: int = 1

@export_group("Visuals")
@export var open_door_texture: Texture2D
@export var closed_door_texture: Texture2D

#visit moves a locaiton from neutral to bonus for faction(s) putting in the effort.
#explore moves a location from hazard to neutral for all factions


var coord: Vector2i
var _task_manager: TaskManager

func _ready() -> void:
	super()
	is_opposed = hazard

	if not willpower_changed.is_connected(_on_willpower_changed):
		willpower_changed.connect(_on_willpower_changed)

	z_index = GameConstants.ZIndex.LOCATION

	_ensure_sprite_setup()
	update_visuals()

func get_interaction_type() -> String:
	return GameConstants.Activity.EXPLORE if is_opposed else GameConstants.Activity.VISIT

func visit(faction: GameConstants.Faction) -> void:
	# moves a locaiton from neutral to bonus for faction(s) putting in the effort.
	if not hazard:
		if faction not in boosts:
			boosts.append(faction)
			update_visuals()

func explore() -> void:
	# moves a location from hazard to neutral for all factions
	if hazard:
		hazard = false
		is_opposed = false
		update_visuals()
		if get_current_willpower() < 0:
			set_willpower(0)

func is_neutral() -> bool:
	return not hazard and boosts.is_empty()

func is_bonus() -> bool:
	return not hazard and not boosts.is_empty()

func is_hazard() -> bool:
	return hazard

func get_aura_value_for_faction(faction: GameConstants.Faction) -> int:
	if is_hazard():
		return -aura_value
	if is_bonus() and (faction in boosts or faction == GameConstants.Faction.PLAYER):
		return aura_value
	return 0

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

func _on_task_event_unit(_idx: int, _faction: int, _unit: Target) -> void:
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
		if hazard:
			sprite.region_rect = Rect2(192, 512, 32, 32) # Door 2 Grated (17g)
		elif not boosts.is_empty():
			sprite.region_rect = Rect2(160, 512, 32, 32) # Door 2 Open (17f)
		else:
			sprite.region_rect = Rect2(128, 512, 32, 32) # Door 2 Closed (17e)

	if hazard:
		sprite.modulate = GameColors.FACTION_ENEMY
	elif boosts.is_empty():
		sprite.modulate = GameColors.WHITE
	else:
		var combined_color := Color(0, 0, 0, 1)
		for f in boosts:
			var c = GameColors.get_faction_color(f)
			combined_color.r += c.r
			combined_color.g += c.g
			combined_color.b += c.b
		
		combined_color.r = clamp(combined_color.r, 0, 1)
		combined_color.g = clamp(combined_color.g, 0, 1)
		combined_color.b = clamp(combined_color.b, 0, 1)
		sprite.modulate = combined_color

	if EventBus:
		EventBus.locations_updated.emit()

func get_attribute_by_index(idx: GameConstants.AttributeIndex) -> int:
	match idx:
		GameConstants.AttributeIndex.GRIT: return grit
		GameConstants.AttributeIndex.FLOW: return flow
		GameConstants.AttributeIndex.GUSTO: return gusto
		GameConstants.AttributeIndex.FOCUS: return focus
		GameConstants.AttributeIndex.SHINE: return shine
		GameConstants.AttributeIndex.SHADE: return shade
	return 0

func interact(unit: Unit, context: CombatResult) -> void:
	interacted.emit(unit, context, self)


func get_current_willpower() -> int:
	return willpower

func get_max_willpower() -> int:
	return base_willpower

func get_hover_info() -> String:
	var info_text: String = loc_name if not loc_name.is_empty() else "Location"
	var faction_name = "Neutral"
	if hazard:
		faction_name = "Hazard"
	elif not boosts.is_empty():
		var names = []
		for f in boosts:
			names.append(GameConstants.get_faction_name(f))
		faction_name = ", ".join(names)
	
	info_text += "\nFaction: " + faction_name
	info_text += "\nWP: %d/%d" % [get_current_willpower(), get_max_willpower()]
	if not description.is_empty():
		info_text += "\n" + description
	return info_text


func get_target_name() -> String:
	return loc_name if not loc_name.is_empty() else id

func get_target_id() -> String:
	return id

func get_subtype_prefix() -> String:
	return get_script().get_global_name().to_lower()

func _on_willpower_changed(_target: Target) -> void:
	if hazard and get_current_willpower() <= 0:
		explore()
