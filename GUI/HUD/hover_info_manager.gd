class_name HoverInfoManager
extends PanelContainer

# Dependencies
var _gameplay_node: Node2D
var _grid: TileMapLayer
var _terrain_map: TerrainMap

# UI Node
var _info_label: Label

var _last_hovered_object = null
var _last_hover_info: String = ""


func _init(state: GameState) -> void:
	# From state
	_terrain_map = state.terrain_map
	var grid: TileMapLayer = state.map_controller.get_grid()
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
		current_parent.remove_child(self )

	# Now add to the root node we stored earlier
	if is_instance_valid(root_node): # Sanity check
		root_node.add_child(self )
	else:
		printerr("Error: Root node is invalid during reparenting of HoverInfoManager.")


func set_info(text: String) -> void:
	if _info_label:
		_info_label.text = text


func _hide_hover_info(_reason: String) -> void:
	hide()
	_last_hovered_object = null
	_last_hover_info = ""


var _last_mouse_cell: Vector2i = Vector2i(-999, -999)

func _process(_delta: float) -> void:
	if not is_instance_valid(_gameplay_node) or not is_instance_valid(_grid):
		_hide_hover_info("invalid dependencies")
		return

	var global_mouse_pos: Vector2 = _gameplay_node.get_global_mouse_position()
	var current_cell: Vector2i = _grid.local_to_map(_grid.to_local(global_mouse_pos))

	if current_cell != _last_mouse_cell:
		_last_mouse_cell = current_cell
		var hovered_object = _get_hovered_object_at(current_cell, global_mouse_pos)

		if hovered_object and hovered_object.has_method("get_hover_info"):
			var info = hovered_object.get_hover_info()
			if not info.is_empty():
				_last_hovered_object = hovered_object
				_last_hover_info = info
				_show_hover_info(info, get_viewport().get_mouse_position())
				return

		_hide_hover_info("no hovered object or empty info")
	elif visible:
		# If the cell is the same but we are visible, we might still need to follow the mouse
		# depending on design, but usually these panels are static per cell or follow strictly.
		# If it follows strictly, we update position but not content.
		var mouse_pos = get_viewport().get_mouse_position()
		_update_position(mouse_pos)

func _update_position(mouse_pos: Vector2) -> void:
	var panel_size = get_combined_minimum_size()
	var viewport_rect = get_viewport().get_visible_rect()
	var new_pos: Vector2 = mouse_pos + Vector2(20, 20)

	if new_pos.x + panel_size.x > viewport_rect.size.x:
		new_pos.x = mouse_pos.x - panel_size.x - 20
	if new_pos.y + panel_size.y > viewport_rect.size.y:
		new_pos.y = mouse_pos.y - panel_size.y - 20

	position = new_pos

func _get_hovered_object_at(coord: Vector2i, _global_mouse_pos: Vector2) -> Object:
	# Units/Occupants
	var occupants: Array[Node2D] = []
	for child in _grid.get_children():
		if child is Node2D and child.visible and _grid.local_to_map(child.position) == coord:
			occupants.append(child)

	for occupant in occupants:
		if occupant is Unit:
			return occupant
		if occupant.has_method("get_hover_info"):
			return occupant

	# Terrain
	if _terrain_map:
		var terrain = _terrain_map.get_terrain(coord)
		if terrain and terrain.has_method("get_hover_info"):
			return terrain

	return null

func _show_hover_info(info: String, mouse_pos: Vector2) -> void:
	if _info_label.text != info:
		_info_label.text = info

	_update_position(mouse_pos)
	if not visible:
		show()

func get_hex_occupants_at_mouse_position() -> Array[Node2D]:
	var current_mouse_pos := _gameplay_node.get_global_mouse_position()
	var local_pos := _grid.to_local(current_mouse_pos)
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

# Note: _get_hovered_object is now replaced by _get_hovered_object_at
