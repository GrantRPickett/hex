class_name Loot
extends Target


@export var inventory: Array[InventoryItem] = []
@export var loot_name: String = ""
@export var is_trapped: bool = false

var _task_manager: TaskManager

func _ready() -> void:
	z_index = GameConstants.ZIndex.LOOT
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

func disarm_trap() -> void:
	is_trapped = false

func can_be_looted_by(unit: Unit, interaction_range: float = 1.5) -> bool:
	return TargetDiscoveryService.can_be_looted_by(unit, self , interaction_range)

func add_items(items: Array[InventoryItem]) -> void:
	for item in items:
		if is_instance_valid(item):
			inventory.append(item.duplicate_instance(true))
	update_visuals()

func is_empty() -> bool:
	return inventory.is_empty()

func get_hover_info() -> String:
	var info_text: String = "Loot:"
	if inventory.is_empty():
		info_text += "\n(Empty)"
	else:
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

func _on_task_event_unit(_idx: int, _faction: int, _unit: Unit) -> void:
	update_visuals()

func _on_task_event_objective(_objective: Objective) -> void:
	update_visuals()

func update_visuals() -> void:
	if not is_instance_valid(sprite):
		return

	var has_task := false
	if _task_manager:
		var tasks = _task_manager.get_active_tasks_for_target(self, GameConstants.Faction.PLAYER)
		has_task = not tasks.is_empty()

	if sprite.region_enabled:
		# 18.a = (0, 17) * 32 = (0, 544) -> closed
		# 18.b = (1, 17) * 32 = (32, 544) -> open
		# Logic: if empty OR has a task, show as open/looted? 
		# Wait, if it has a task, it's not empty. If it shows as open when has_task=true, 
		# it might mean it's "ready to be looted" or "important".
		if is_empty() or has_task:
			sprite.region_rect = Rect2(32, 544, 32, 32)
		else:
			sprite.region_rect = Rect2(0, 544, 32, 32)
