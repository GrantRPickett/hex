class_name AnimationRequestService
extends Node

signal animation_requested(request_id: StringName, payload: Dictionary)
signal animation_completed(request_id: StringName, payload: Dictionary)

class StyleIds:
	const DEFAULT := &"default"
	const UNIT_MOVE := &"unit_move"
	const HUD_WARNING := &"hud_warning"
	const HUD_FEEDBACK := &"hud_feedback"
	const UNIT_DEATH_ROTATE := &"unit_death_rotate"

var _grid: Node2D
var _unit_manager: UnitManager
var _styles: Dictionary[StringName, AnimationStyle] = {}
var _default_style: AnimationStyle = AnimationStyle.new()
var _tween_factory: Callable = Callable()
var _batch_buffer := BatchAnimationBuffer.new()
var _batch_deferred := false # Flag to enable/disable buffering
var _is_flushing := false

func should_skip_delays() -> bool:
	if _batch_deferred:
		return true
	var game_config = GameConfig
	if game_config:
		var speed = game_config.get_value(GameConfig.Paths.GAMEPLAY_ANIMATION_SPEED, GameConstants.Settings.ANIMATION_SPEED_NORMAL)
		return speed == GameConstants.Settings.ANIMATION_SPEED_SKIP
	return false

func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
	_grid = config.grid
	_unit_manager = state.unit_manager
	_default_style.style_id = StyleIds.DEFAULT
	_default_style.duration = GameConstants.UI.DEFAULT_ANIMATION_DURATION
	_default_style.transition = Tween.TRANS_SINE
	_default_style.ease = Tween.EASE_OUT
	_styles.clear()
	var style_set: AnimationStyleSet = config.animation_style_set # Access style_set from config
	if style_set:
		for style_value in style_set.styles:
			var style: AnimationStyle = style_value
			if style == null:
				continue
			var style_id: StringName = style.style_id
			if String(style_id).is_empty():
				continue
			_styles[style_id] = style

func set_tween_factory(factory: Callable) -> void:
	_tween_factory = factory

func request_unit_move(unit: Unit, coord: Vector2i, style_id: StringName = StyleIds.UNIT_MOVE) -> void:
	if not is_instance_valid(unit):
		return
	var style: AnimationStyle = _get_style(style_id)

	# Check for batching
	if _is_batch_mode_active():
		var start_pos = unit.position
		# We need to compute path points here to buffer them
		var info = _prepare_move_data(unit, coord, style)
		_batch_buffer.add_move(unit, start_pos, info.path_points, info.duration, style, coord, style_id)
		return

	var path_points: Array[Vector2] = []
	var use_path := false

	var current_pos = unit.position
	if is_instance_valid(_grid) and unit.get("movement") and unit.movement.has_tentative_move():
		var tentative_path: Array = unit.movement.get_tentative_path()
		var idx: int = tentative_path.find(coord)
		if idx != -1:
			use_path = true
			for i in range(idx + 1):
				path_points.append(_grid.map_to_local(tentative_path[i]))

	if not use_path:
		var target: Vector2 = unit.position
		if is_instance_valid(_grid):
			target = _grid.map_to_local(coord)
		path_points.append(target)

	var final_target_pos = path_points.back() + style.position_offset
	var duration: float = get_effective_duration(style.duration)

	animation_requested.emit(style_id, {
		"unit": unit as Node2D,
		"coord": coord,
		"target_position": final_target_pos
	})
	var tween: Tween = _create_tween_for(unit)
	if tween == null:
		return

	for point in path_points:
		var step_target = point + style.position_offset
		# Sprite flipping logic
		if unit.get("sprite") and is_instance_valid(unit.sprite):
			var delta_x = step_target.x - current_pos.x
			if abs(delta_x) > GameConstants.UI.UNIT_SPRITE_FLIP_THRESHOLD: # Threshold to avoid jitter
				var should_flip = delta_x > 0 # Face right if moving right
				tween.tween_callback(func(): unit.sprite.flip_h = should_flip)

		tween.tween_property(unit, "position", step_target, duration).set_trans(style.transition).set_ease(style.ease)
		current_pos = step_target

	_connect_completion(tween, style_id, {"unit": unit, "coord": coord})

func on_unit_moved(index: int, coord: Vector2i) -> void:
	if not _unit_manager:
		return
	var unit: Unit = _unit_manager.get_unit(index)
	if unit:
		request_unit_move(unit, coord)

func request_feedback_float(node: Control, offset: Vector2, style_id: StringName = StyleIds.HUD_FEEDBACK, auto_free: bool = true) -> void:
	if not is_instance_valid(node):
		return
	var style: AnimationStyle = _get_style(style_id)

	if _is_batch_mode_active():
		_batch_buffer.add_generic("request_feedback_float", [node, offset, style_id, auto_free])
		return

	var duration: float = get_effective_duration(style.duration)
	animation_requested.emit(style_id, {
		"node": node,
		"offset": offset
	})
	var tween: Tween = _create_tween_for(node)
	if tween == null:
		return
	tween.tween_property(node, "position", node.position + offset + style.position_offset, duration).set_trans(style.transition).set_ease(style.ease)
	var fade_to: float = float(style.metadata.get("fade_to", 0.0))
	var fade_duration: float = get_effective_duration(float(style.metadata.get("fade_duration", style.duration)))
	var fade_transition: Tween.TransitionType = style.metadata.get("fade_transition", style.transition) as Tween.TransitionType
	var fade_ease: Tween.EaseType = style.metadata.get("fade_ease", style.ease) as Tween.EaseType
	tween.parallel().tween_property(node, "modulate:a", fade_to, fade_duration).set_trans(fade_transition).set_ease(fade_ease)
	if auto_free:
		tween.tween_callback(node.queue_free)
	_connect_completion(tween, style_id, {"node": node})

func request_warning_flash(node: Control, style_id: StringName = StyleIds.HUD_WARNING) -> void:
	if not is_instance_valid(node):
		return
	var style: AnimationStyle = _get_style(style_id)

	if _is_batch_mode_active():
		_batch_buffer.add_generic("request_warning_flash", [node, style_id])
		return

	var fade_in: float = get_effective_duration(float(style.metadata.get("fade_in_duration", style.duration)))
	var hold: float = get_effective_duration(float(style.metadata.get("hold_duration", 1.0)))
	var fade_out: float = get_effective_duration(float(style.metadata.get("fade_out_duration", style.duration)))
	var max_alpha: float = float(style.metadata.get("max_alpha", 1.0))
	var min_alpha: float = float(style.metadata.get("min_alpha", 0.0))
	var fade_out_transition: Tween.TransitionType = style.metadata.get("fade_out_transition", style.transition) as Tween.TransitionType
	var fade_out_ease: Tween.EaseType = style.metadata.get("fade_out_ease", style.ease) as Tween.EaseType
	animation_requested.emit(style_id, {"node": node})
	var tween: Tween = _create_tween_for(node)
	if tween == null:
		return
	tween.tween_property(node, "modulate:a", max_alpha, fade_in).set_trans(style.transition).set_ease(style.ease)
	if hold > 0.0:
		tween.tween_interval(hold)
	tween.tween_property(node, "modulate:a", min_alpha, fade_out).set_trans(fade_out_transition).set_ease(fade_out_ease)
	tween.tween_callback(node.queue_free)
	_connect_completion(tween, style_id, {"node": node})

func request_property_animation(target: Object, property: String, value, style_id: StringName = StyleIds.DEFAULT, on_complete: Callable = Callable()) -> void:
	if target == null:
		return
	var style: AnimationStyle = _get_style(style_id)

	if _is_batch_mode_active():
		_batch_buffer.add_generic("request_property_animation", [target, property, value, style_id, on_complete])
		return

	var duration: float = get_effective_duration(style.duration)
	animation_requested.emit(style_id, {
		"node": target,
		"property": property,
		"value": value
	})
	var tween: Tween = _create_tween_for(target)
	if tween == null:
		return
	tween.tween_property(target, property, value, duration).set_trans(style.transition).set_ease(style.ease)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	_connect_completion(tween, style_id, {"node": target, "property": property})

func _get_style(style_id: StringName) -> AnimationStyle:
	var style: AnimationStyle = _styles.get(style_id)
	if style:
		return style
	if style_id != StyleIds.DEFAULT:
		GameLogger.warning(GameLogger.Category.UI, "[AnimationRequestService] Missing animation style '%s'. Using default." % [style_id])
	return _default_style

func _create_tween_for(target: Object) -> Object:
	if _tween_factory and _tween_factory.is_valid():
		var created = _tween_factory.call(target)
		return created
	return target.create_tween()

func _connect_completion(tween, request_id: StringName, payload: Dictionary) -> void:
	if tween == null:
		return
	if tween.has_signal("finished"):
		tween.finished.connect(func():
			animation_completed.emit(request_id, payload)
		, CONNECT_ONE_SHOT)

func set_batch_deferred(deferred: bool) -> void:
	_batch_deferred = deferred
	if not deferred and not _batch_buffer.is_empty():
		flush_batch()

func flush_batch() -> void:
	if _batch_buffer.is_empty() or _is_flushing:
		return

	_is_flushing = true
	var requests = _batch_buffer.get_requests()
	for req in requests:
		if req.type == "move":
			_execute_move_animation(req)
		else:
			callv(req.method, req.args)
	_batch_buffer.clear()
	_is_flushing = false

func _is_batch_mode_active() -> bool:
	if not _batch_deferred or _is_flushing:
		return false
	var game_config = GameConfig
	if game_config:
		return game_config.get_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, false)
	return false

func _prepare_move_data(unit: Unit, coord: Vector2i, style: AnimationStyle) -> Dictionary:
	var path_points: Array[Vector2] = []
	var use_path := false

	if is_instance_valid(_grid) and unit.get("movement") and unit.movement.has_tentative_move():
		var tentative_path: Array = unit.movement.get_tentative_path()
		var idx: int = tentative_path.find(coord)
		if idx != -1:
			use_path = true
			for i in range(idx + 1):
				path_points.append(_grid.map_to_local(tentative_path[i]))

	if not use_path:
		var target: Vector2 = unit.position
		if is_instance_valid(_grid):
			target = _grid.map_to_local(coord)
		path_points.append(target)

	var duration: float = get_effective_duration(style.duration)
	return {
		"path_points": path_points,
		"duration": duration
	}

func _execute_move_animation(req: Dictionary) -> void:
	var unit: Unit = req.unit
	if not is_instance_valid(unit):
		return

	var style: AnimationStyle = req.style
	var path_points: Array[Vector2] = req.path_points
	var duration: float = req.duration
	var coord: Vector2i = req.coord
	var style_id: StringName = req.style_id

	# Temporarily move unit back to start position for the animation
	var final_pos = unit.position
	unit.position = req.start_pos
	var current_pos = req.start_pos

	animation_requested.emit(style_id, {
		"unit": unit as Node2D,
		"coord": coord,
		"target_position": path_points.back() + style.position_offset
	})

	var tween: Tween = _create_tween_for(unit)
	if tween == null:
		unit.position = final_pos # Restore if tween fails
		return

	for point in path_points:
		var step_target = point + style.position_offset
		# Sprite flipping logic
		if unit.get("sprite") and is_instance_valid(unit.sprite):
			var delta_x = step_target.x - current_pos.x
			if abs(delta_x) > GameConstants.UI.UNIT_SPRITE_FLIP_THRESHOLD:
				var should_flip = delta_x > 0
				tween.tween_callback(func(): unit.sprite.flip_h = should_flip)

		tween.tween_property(unit, "position", step_target, duration).set_trans(style.transition).set_ease(style.ease)
		current_pos = step_target

	_connect_completion(tween, style_id, {"unit": unit, "coord": coord})

func get_effective_duration(base_duration: float) -> float:
	var multiplier := 1.0
	var game_config = GameConfig
	if game_config:
		var speed = game_config.get_value(GameConfig.Paths.GAMEPLAY_ANIMATION_SPEED, GameConstants.Settings.ANIMATION_SPEED_NORMAL)
		match speed:
			GameConstants.Settings.ANIMATION_SPEED_SLOW: multiplier = GameConstants.UI.SPEED_SLOW_MULTIPLIER
			GameConstants.Settings.ANIMATION_SPEED_NORMAL: multiplier = GameConstants.UI.SPEED_NORMAL_MULTIPLIER
			GameConstants.Settings.ANIMATION_SPEED_FAST: multiplier = GameConstants.UI.SPEED_FAST_MULTIPLIER
			GameConstants.Settings.ANIMATION_SPEED_SKIP: multiplier = GameConstants.UI.SPEED_SKIP_MULTIPLIER
	return base_duration * multiplier
