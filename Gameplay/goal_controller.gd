class_name GoalController
extends Node

signal goal_reached

var _goal_manager: GoalManager
var _unit_manager: UnitManager
var _require_all_units: bool = false
var _goal_reached_state: bool = false

func setup(goal_manager: GoalManager, unit_manager: UnitManager) -> void:
	_goal_manager = goal_manager
	_unit_manager = unit_manager

func set_require_all_units(require: bool) -> void:
	_require_all_units = require

func check_goal_progress() -> void:
	if _goal_reached_state:
		return

	var idx := _unit_manager.get_selected_index()
	if idx == -1:
		return

	var target: Vector2i = _goal_manager.get_target(idx)

	if _unit_manager.get_coord(idx) != target:
		return

	_unit_manager.set_goal_reached(idx, true)

	if _require_all_units:
		if _unit_manager.are_all_goals_reached():
			_goal_reached_state = true
			goal_reached.emit()
		return

	_goal_reached_state = true
	goal_reached.emit()

func is_goal_reached() -> bool:
	return _goal_reached_state

func reset_goal_state() -> void:
	_goal_reached_state = false

func create_target_texture(primary: Color, secondary: Color) -> Texture2D:
	var size := 64
	var center := Vector2(size * 0.5, size * 0.5)
	var outer_radius := size * 0.45
	var middle_radius := size * 0.25
	var inner_radius := size * 0.1
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var pos := Vector2(x + 0.5, y + 0.5)
			var dist := pos.distance_to(center)
			var color := Color(0, 0, 0, 0)
			if dist <= inner_radius:
				color = primary
			elif dist <= middle_radius:
				color = secondary
			elif dist <= outer_radius:
				color = primary
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)