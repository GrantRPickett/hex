class_name GoalController
extends Node

signal goal_reached
signal game_over

var _goal_manager: GoalManager
var _unit_manager: UnitManager
var _require_all_units: bool = false
var _goal_reached_state: bool = false
var _game_over_state: bool = false

func setup(goal_manager: GoalManager, unit_manager: UnitManager) -> void:
	_goal_manager = goal_manager
	_unit_manager = unit_manager
	if _goal_manager:
		if not _goal_manager.goal_completed.is_connected(_on_goal_completed):
			_goal_manager.goal_completed.connect(_on_goal_completed)

func set_require_all_units(require: bool) -> void:
	_require_all_units = require

func check_goal_progress() -> void:
	if _goal_reached_state or _game_over_state:
		return

	# Win Condition: Player completes all required goals
	if _goal_manager.are_all_required_goals_completed():
		_goal_reached_state = true
		goal_reached.emit()
		return

	# Loss Condition: Enemies complete majority (>50%) of required goals
	var total_required = _goal_manager.get_total_required_goals_count()
	if total_required > 0:
		var enemy_completed = _goal_manager.get_completed_required_goals_count(Unit.Faction.ENEMY)
		if enemy_completed > float(total_required) / 2.0:
			_game_over_state = true
			game_over.emit()
			return

func is_goal_reached() -> bool:
	return _goal_reached_state

func process_turn_progress() -> void:
	#_goal_manager.process_turn_progress(_unit_manager)
	pass

func _on_goal_completed(index: int, faction: int) -> void:
	check_goal_progress()

func reset_goal_state() -> void:
	_goal_reached_state = false

func get_goal(index: int) -> Goal:
	if _goal_manager:
		return _goal_manager.get_goal_node(index) as Goal
	return null

func create_memento() -> Dictionary:
	if _goal_manager:
		return _goal_manager.create_memento()
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	if _goal_manager:
		_goal_manager.restore_from_memento(memento)


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
