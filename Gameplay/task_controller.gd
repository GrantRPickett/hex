class_name TaskController
extends Node

signal task_reached
signal game_over

var _location_manager: LocationManager
var _unit_manager: UnitManager
var _task_reached_state: bool = false
var _game_over_state: bool = false

func setup(location_manager: LocationManager, unit_manager: UnitManager) -> void:
	_location_manager = location_manager
	_unit_manager = unit_manager
	if _location_manager:
		if not _location_manager.task_completed.is_connected(_on_task_completed):
			_location_manager.task_completed.connect(_on_task_completed)

func check_location_progress() -> void:
	if _task_reached_state or _game_over_state:
		return

	# Win Condition: Player completes all required locations
	if _location_manager.are_all_required_tasks_completed():
		_task_reached_state = true
		task_reached.emit()
		return

	# Loss Condition: Enemies complete majority (>50%) of required locations
	var total_required = _location_manager.get_total_required_tasks_count()
	if total_required > 0:
		var enemy_completed = _location_manager.get_completed_required_tasks_count(Unit.Faction.ENEMY)
		if enemy_completed > float(total_required) / 2.0:
			_game_over_state = true
			game_over.emit()
			return

func is_task_reached() -> bool:
	return _task_reached_state

func process_turn_progress() -> void:
	#_location_manager.process_turn_progress(_unit_manager)
	pass

func _on_task_completed(index: int, faction: int) -> void:
	check_location_progress()

func reset_task_state() -> void:
	_task_reached_state = false

func get_target_task(index: int) -> TargetTask:
	if _location_manager:
		return _location_manager.get_target_task_node(index) as TargetTask
	return null

func create_memento() -> Dictionary:
	if _location_manager:
		return _location_manager.create_memento()
	return {}

func restore_from_memento(memento: Dictionary) -> void:
	if _location_manager:
		_location_manager.restore_from_memento(memento)


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
