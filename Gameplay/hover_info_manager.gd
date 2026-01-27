class_name HoverInfoManager
extends Node

const INFO_PANEL_PATH := "res://GUI/hover_info_panel.tscn"

var _hover_info_panel: PanelContainer
var _gameplay_node: Node2D
var _camera: Camera2D
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _loot_manager: LootManager
var _grid: TileMapLayer

func _init(gameplay_node: Node2D, camera: Camera2D, unit_manager: UnitManager, goal_manager: GoalManager, loot_manager: LootManager) -> void:
	_gameplay_node = gameplay_node
	_camera = camera
	_unit_manager = unit_manager
	_goal_manager = goal_manager
	_loot_manager = loot_manager
	_grid = _gameplay_node.get_node("Grid")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hover_info_panel = preload(INFO_PANEL_PATH).instantiate()
	_hover_info_panel.hide()
	get_tree().root.add_child(_hover_info_panel)

func _process(delta: float) -> void:
	var mouse_pos = _gameplay_node.get_viewport().get_mouse_position()
	var hovered_object = _get_hovered_object()

	if hovered_object:
		if hovered_object.has_method("get_hover_info"):
			var info = hovered_object.get_hover_info()
			if not info.is_empty():
				_hover_info_panel.set_info(info)
				_hover_info_panel.position = mouse_pos + Vector2(10, 10)
				_hover_info_panel.show()
				return
	_hover_info_panel.hide()

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

func _get_hovered_object() -> Node:
	var unit = get_unit_at_mouse_position()
	if unit:
		return unit

	var occupants = get_hex_occupants_at_mouse_position()
	for occupant in occupants:
		if occupant.has_method("get_hover_info") and occupant.visible:
			return occupant

	return null
