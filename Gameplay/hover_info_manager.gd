class_name HoverInfoManager
extends PanelContainer

# Dependencies
var _gameplay_node: Node2D
var _grid: TileMapLayer
var _terrain_map: TerrainMap

# UI Node
var _info_label: Label

var _last_hovered_object = null
var _last_hover_info = ""


func _init(services: GameSessionServices) -> void:
	# From services
	_terrain_map = services.terrain_map
	var grid = services.grid_controller.get_grid()
	_grid = grid
	# This needs a valid grid node, which is asserted in the builder
	if is_instance_valid(grid):
		_gameplay_node = grid.get_parent()

	# Configure the panel properties
	custom_minimum_size = Vector2(150, 50)
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create and configure the label child
	_info_label = Label.new()
	add_child(_info_label)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	call_deferred("_reparent_to_root")

	hide()


func _reparent_to_root() -> void:
	# Reparent self to the root viewport for proper UI layering and positioning
	var root_node = get_tree().root # Get the root node while self is still in the tree

	var current_parent = get_parent()
	if current_parent:
		current_parent.remove_child(self)

	# Now add to the root node we stored earlier
	if is_instance_valid(root_node): # Sanity check
		root_node.add_child(self)
	else:
		printerr("Error: Root node is invalid during reparenting of HoverInfoManager.")


func set_info(text: String) -> void:
	if _info_label:
		_info_label.text = text


func _get_object_display_info(hovered_object: Object, info: String) -> Dictionary:
	var object_name = "unknown"
	if hovered_object is Node:
		object_name = hovered_object.name
	elif hovered_object.has_method("get_name"):
		object_name = hovered_object.get_name()
	else:
		object_name = str(hovered_object)

	var object_type
	match hovered_object:
		Unit:
			object_type = "Unit"
		Loot:
			object_type = "Loot"
		location:
			object_type = "location"
		TerrainTile:
			object_type = "Terrain"
		TileMapLayer:
			object_type = "TileMap"
		TerrainMap:
			object_type = "TerrainMap"
		Node:
			object_type = "Node"
		_:
			object_type = "unknown_type"

	return {"type": object_type, "name": object_name}

func _hide_hover_info(reason: String) -> void:
	hide()
	_last_hovered_object = null
	_last_hover_info = ""


func _show_hover_info(info: String, mouse_pos: Vector2) -> void:
	set_info(info)

	var panel_size = get_combined_minimum_size()
	var viewport_rect = get_viewport().get_visible_rect()
	var new_pos = mouse_pos + Vector2(20, 20)

	if new_pos.x + panel_size.x > viewport_rect.size.x:
		new_pos.x = mouse_pos.x - panel_size.x - 20

	if new_pos.y + panel_size.y > viewport_rect.size.y:
		new_pos.y = mouse_pos.y - panel_size.y - 20

	position = new_pos
	if not visible:
		print("HoverInfoManager: Showing at position: ", new_pos)
	show()


func _process(_delta: float) -> void:
	if not is_instance_valid(_gameplay_node):
		_hide_hover_info("because _gameplay_node is invalid")
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var hovered_object = _get_hovered_object()

	if hovered_object and hovered_object.has_method("get_hover_info"):
		var info = hovered_object.get_hover_info()
		if not info.is_empty():
			if hovered_object != _last_hovered_object or info != _last_hover_info:
				_get_object_display_info(hovered_object, info)
			_last_hovered_object = hovered_object
			_last_hover_info = info

			_show_hover_info(info, mouse_pos)
			return

	_hide_hover_info("no hovered object or empty info")

func get_hex_occupants_at_mouse_position() -> Array[Node2D]:
	var mouse_pos := _gameplay_node.get_global_mouse_position()
	var local_pos := _grid.to_local(mouse_pos)
	var coord := _grid.local_to_map(local_pos)

	var occupants: Array[Node2D] = []
	for child in _grid.get_children():
		if child is Node2D and _grid.local_to_map(child.position) == coord:
			occupants.append(child)
	return occupants


func get_unit_at_mouse_position() -> Unit:
	var occupants = get_hex_occupants_at_mouse_position()
	for occupant in occupants:
		if occupant is Unit and occupant.visible:
			return occupant
	return null


func _get_hovered_object() -> Object:
	var unit = get_unit_at_mouse_position()
	if unit:
		return unit

	var occupants = get_hex_occupants_at_mouse_position()
	for occupant in occupants:
		if occupant.has_method("get_hover_info") and occupant.visible:
			return occupant

	# If no unit or occupant, check terrain
	var mouse_pos := _gameplay_node.get_global_mouse_position()
	var local_pos := _grid.to_local(mouse_pos)
	var coord := _grid.local_to_map(local_pos)
	var terrain := _terrain_map.get_terrain(coord)
	if terrain and terrain.has_method("get_hover_info"):
		return terrain

	return null
