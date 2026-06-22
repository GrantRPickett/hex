class_name Loot
extends Target
# Loot: A target that can be searched for items.


@export var inventory: Array[InventoryItem] = []
@export var loot_name: String = ""
@export var is_trapped: bool = false

var _task_manager: TaskManager

func _ready() -> void:
	super()
	is_opposed = is_trapped
	z_index = GameConstants.ZIndex.LOOT
	_ensure_sprite_setup()
	update_visuals()

func get_interaction_type() -> String:
	return GameConstants.Activity.TRAPPED if is_opposed else GameConstants.Activity.GATHER

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

func disarm_trap() -> void:
	is_trapped = false
	is_opposed = false
	update_visuals()

func add_items(items: Array[InventoryItem]) -> void:
	for item in items:
		if is_instance_valid(item):
			inventory.append(item.duplicate_instance(true))
	update_visuals()

func is_empty() -> bool:
	return inventory.is_empty()

func get_hover_info() -> String:
	var info_text: String = loot_name if not loot_name.is_empty() else "Loot"
	info_text += "\nWP: %d/%d" % [get_current_willpower(), get_max_willpower()]
	if not inventory.is_empty():
		info_text += "\nItems:"
		for item in inventory:
			info_text += "\n- " + item.get_item_name()
	return info_text

func take_all_items() -> Array[InventoryItem]:
	var taken: Array[InventoryItem] = []
	for item in inventory:
		if item:
			taken.append(item.duplicate_instance(false))
	inventory.clear()
	update_visuals()
	return taken

func set_task_manager(tm: TaskManager) -> void:
	if _task_manager != tm:
		_task_manager = tm
		if _task_manager:
			if not _task_manager.task_updated.is_connected(_on_task_event):
				_task_manager.task_updated.connect(_on_task_event)
			if not _task_manager.task_completed.is_connected(_on_task_event_unit):
				_task_manager.task_completed.connect(_on_task_event_unit)
			if not _task_manager.objective_updated.is_connected(_on_task_event_objective):
				_task_manager.objective_updated.connect(_on_task_event_objective)
		update_visuals()

func _on_task_event(_idx: int, _faction: int) -> void:
	update_visuals()

func _on_task_event_unit(_idx: int, _faction: int, _unit: Target) -> void:
	update_visuals()

func _on_task_event_objective(_objective: Objective) -> void:
	update_visuals()

func update_visuals() -> void:
	if not is_instance_valid(sprite):
		return

	# Note: Highlight for tasks is handled by the TaskUI overlay if applicable

	if sprite.region_enabled:
		if is_empty():
			sprite.region_rect = Rect2(32, 544, 32, 32) # Open
		else:
			sprite.region_rect = Rect2(0, 544, 32, 32) # Closed

	if is_trapped:
		sprite.modulate = GameColors.FACTION_ENEMY
	else:
		sprite.modulate = GameColors.WHITE


func get_target_name() -> String:
	return loot_name if not loot_name.is_empty() else id

func get_target_id() -> String:
	return id

func get_subtype_prefix() -> String:
	return get_script().get_global_name().to_lower()
