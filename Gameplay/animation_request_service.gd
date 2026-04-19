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
	const INTERACTION_CLASH := &"interaction_clash"
	const INTERACTION_JUMP := &"interaction_jump"
	const INTERACTION_SHAKE := &"interaction_shake"

var _grid: Node2D
var _unit_manager: UnitManager
var _camera_controller: CameraController
var _styles: Dictionary[StringName, AnimationStyle] = {}
var _default_style: AnimationStyle = AnimationStyle.new()
var _tween_factory: Callable = Callable()
var _batch_buffer := BatchAnimationBuffer.new()
var _batch_deferred := false # Flag to enable/disable buffering
var _is_flushing := false
var _suppress_requests := false

func set_suppress_requests(suppress: bool) -> void:
	_suppress_requests = suppress

# Animation Queue State
var _animation_queue: Array[Dictionary] = []
var _is_playing_queue := false

func should_skip_delays() -> bool:
	if _batch_deferred:
		return true
	var game_config = GameConfig
	if game_config:
		var speed = game_config.get_value(GameConfig.Paths.GAMEPLAY_ANIMATION_SPEED, GameConstants.Settings.ANIMATION_SPEED_NORMAL)
		return speed == GameConstants.Settings.ANIMATION_SPEED_SKIP
	return false

func is_reduced_motion_enabled() -> bool:
	var game_config = GameConfig
	if game_config:
		return bool(game_config.get_value(GameConfig.Paths.ACCESSIBILITY_REDUCED_MOTION, false))
	return false

func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
	_grid = config.grid
	_unit_manager = state.unit_manager
	_camera_controller = state.camera_controller
	
	if _unit_manager:
		# Use path-based signal for atomic movement
		if _unit_manager.has_signal("unit_path_moved"):
			_unit_manager.unit_path_moved.connect(_on_unit_path_moved)
	
	_default_style.style_id = StyleIds.DEFAULT
	_default_style.duration = GameConstants.UI.DEFAULT_ANIMATION_DURATION
	_default_style.transition = Tween.TRANS_SINE
	_default_style.ease = Tween.EASE_OUT
	_styles.clear()
	var style_set: AnimationStyleSet = config.animation_style_set 
	if style_set:
		for style in style_set.styles:
			if style and not String(style.style_id).is_empty():
				_styles[style.style_id] = style

func _on_unit_path_moved(index: int, path: Array[Vector2i]) -> void:
	if not _unit_manager: return
	var unit: Unit = _unit_manager.get_unit(index)
	if unit:
		var style: AnimationStyle = _get_style(StyleIds.UNIT_MOVE)
		var path_points: Array[Vector2] = []
		for coord in path:
			path_points.append(_grid.map_to_local(coord))
		_enqueue_animation({
			"type": "move",
			"unit": unit,
			"coord": path.back(),
			"callable": func(): _run_move_animation(unit, path_points, style, path.back(), StyleIds.UNIT_MOVE)
		})

func _run_move_animation(unit: Node2D, path_points: Array[Vector2], style: AnimationStyle, coord: Vector2i, style_id: StringName) -> void:
	var final_target_pos = path_points.back() + style.position_offset
	var duration: float = get_effective_duration(style.duration)

	animation_requested.emit(style_id, {
		"unit": unit,
		"coord": coord,
		"target_position": final_target_pos
	})

	var tween = _create_tween_for(unit)
	if tween == null: 
		_on_queue_item_completed()
		return

	var sprite = _get_sprite(unit)
	var is_inhibited = _is_animation_inhibited()
	var camera_pan_tween = _initiate_camera_tracking(path_points, duration, is_inhibited)
		
	_process_move_steps(unit, sprite, path_points, style, tween, duration, is_inhibited)

	tween.finished.connect(func():
		if camera_pan_tween: camera_pan_tween.kill()
		_on_queue_item_completed()
	, CONNECT_ONE_SHOT)
	_connect_completion(tween, style_id, {"unit": unit, "coord": coord})

func _initiate_camera_tracking(path_points: Array[Vector2], duration: float, is_inhibited: bool) -> Tween:
	if not _camera_controller: return null
	if is_inhibited:
		_camera_controller.center_on_position(path_points.back())
		return null
	return create_tween()

func _process_move_steps(unit: Node2D, sprite: Sprite2D, path_points: Array[Vector2], style: AnimationStyle, tween: Tween, duration: float, is_inhibited: bool) -> void:
	if path_points.is_empty():
		tween.tween_interval(0.0)
		return

	var current_pos = unit.position
	for point in path_points:
		var step_target = point + style.position_offset
		_apply_flipping(tween, sprite, current_pos, step_target)
		
		# Pan camera only if not inhibited
		if not is_inhibited and _camera_controller:
			# Note: We need a way to reference the pan tween created in _initiate_camera_tracking
			# For simplicity, we create or update it here.
			pass 
			
		tween.tween_property(unit, "position", step_target, duration).set_trans(style.transition).set_ease(style.ease)
		current_pos = step_target

## Request a clash animation between an attacker and a target.
func request_interact_clash(attacker: Node2D, target: Node2D, direction_getter: Callable, center_camera: bool = true) -> void:
	if _is_animation_inhibited(): return
	var displacement = float(GameConstants.TILE_SIZE.x) * 0.3
	var style_id = StyleIds.INTERACTION_CLASH
	
	_enqueue_animation({
		"type": "clash",
		"attacker": attacker,
		"target": target,
		"callable": func():
			var direction: Vector2 = direction_getter.call()
			if center_camera and _camera_controller:
				_camera_controller.center_on_position((attacker.position + target.position) * 0.5)
			
			var attacker_sprite = _get_sprite(attacker)
			var target_sprite = _get_sprite(target)
			
			var attacker_start = attacker_sprite.position if attacker_sprite else Vector2.ZERO
			var target_start = target_sprite.position if target_sprite else Vector2.ZERO
			
			var style = _get_style(style_id)
			var duration = get_effective_duration(style.duration)
			
			var tween = _create_tween_for(attacker)
			if tween == null or not is_instance_valid(attacker_sprite):
				_on_queue_item_completed()
				return
				
			var has_tweeners := false
			if attacker_sprite:
				tween.tween_property(attacker_sprite, "position", attacker_start + direction * displacement, duration).set_trans(style.transition).set_ease(style.ease)
				tween.tween_property(attacker_sprite, "position", attacker_start, duration).set_trans(style.transition).set_ease(style.ease)
				has_tweeners = true
			
			if target_sprite:
				var parallel_tween = tween.parallel()
				parallel_tween.tween_property(target_sprite, "position", target_start - direction * displacement, duration).set_trans(style.transition).set_ease(style.ease)
				tween.tween_property(target_sprite, "position", target_start, duration).set_trans(style.transition).set_ease(style.ease)
				has_tweeners = true
				
			if has_tweeners:
				tween.finished.connect(func():
					animation_completed.emit(StyleIds.INTERACTION_CLASH, {"attacker": attacker, "target": target})
					_on_queue_item_completed()
				, CONNECT_ONE_SHOT)
			else:
				# No sprites found, complete immediately
				animation_completed.emit(StyleIds.INTERACTION_CLASH, {"attacker": attacker, "target": target})
				_on_queue_item_completed()
	})

func request_interact_shake(node: Node2D, center_camera: bool = true) -> void:
	if _is_animation_inhibited(): return
	var style_id = StyleIds.INTERACTION_SHAKE
	
	_enqueue_animation({
		"type": "shake",
		"node": node,
		"callable": func():
			if center_camera and _camera_controller:
				_camera_controller.center_on_position(node.position)
			
			var sprite = _get_sprite(node)
			if not sprite:
				animation_completed.emit(StyleIds.INTERACTION_SHAKE, {"node": node})
				_on_queue_item_completed()
				return
				
			var start_pos = sprite.position
			var style = _get_style(style_id)
			var duration = get_effective_duration(style.duration)
			var shake_intensity = float(GameConstants.TILE_SIZE.x) * 0.1
			
			var tween = _create_tween_for(sprite)
			if tween == null or not is_instance_valid(sprite):
				animation_completed.emit(StyleIds.INTERACTION_SHAKE, {"node": node})
				_on_queue_item_completed()
				return
				
			# Create a shake effect by rapidly moving the sprite
			tween.tween_property(sprite, "position", start_pos + Vector2(shake_intensity, 0), duration * 0.25).set_trans(style.transition).set_ease(style.ease)
			tween.tween_property(sprite, "position", start_pos + Vector2(-shake_intensity, 0), duration * 0.25).set_trans(style.transition).set_ease(style.ease)
			tween.tween_property(sprite, "position", start_pos + Vector2(0, shake_intensity), duration * 0.25).set_trans(style.transition).set_ease(style.ease)
			tween.tween_property(sprite, "position", start_pos, duration * 0.25).set_trans(style.transition).set_ease(style.ease)
			
			tween.finished.connect(func():
				animation_completed.emit(StyleIds.INTERACTION_SHAKE, {"node": node})
				_on_queue_item_completed()
			, CONNECT_ONE_SHOT)
	})

func request_interact_jump(node: Node2D, center_camera: bool = true) -> void:
	if _is_animation_inhibited(): return
	var style_id = StyleIds.INTERACTION_JUMP
	
	_enqueue_animation({
		"type": "jump",
		"node": node,
		"callable": func():
			if center_camera and _camera_controller:
				_camera_controller.center_on_position(node.position)
			
			var sprite = _get_sprite(node)
			if not sprite:
				animation_completed.emit(StyleIds.INTERACTION_JUMP, {"node": node})
				_on_queue_item_completed()
				return
				
			var start_pos = sprite.position
			var style = _get_style(style_id)
			var duration = get_effective_duration(style.duration)
			var jump_height = float(GameConstants.TILE_SIZE.y) * 0.4
			
			var tween = _create_tween_for(sprite)
			if tween == null:
				animation_completed.emit(StyleIds.INTERACTION_JUMP, {"node": node})
				_on_queue_item_completed()
				return
				
			# Jump up and down
			tween.tween_property(sprite, "position", start_pos + Vector2(0, -jump_height), duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position", start_pos, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			tween.finished.connect(func():
				animation_completed.emit(StyleIds.INTERACTION_JUMP, {"node": node})
				_on_queue_item_completed()
			, CONNECT_ONE_SHOT)
	})

func _request_impulse_animation(node: Node2D, property: String, impulse: Variant, style_id: StringName, center_camera: bool = false) -> void:
	_enqueue_animation({
		"type": "impulse",
		"node": node,
		"callable": func():
			if center_camera and _camera_controller:
				_camera_controller.center_on_position(node.position)
				
			var sprite = _get_sprite(node)
			if not sprite:
				_on_queue_item_completed()
				return
				
			var start_val = sprite.get(property)
			var style = _get_style(style_id)
			var duration = get_effective_duration(style.duration)
			
			var tween = _create_tween_for(sprite)
			if tween == null or not is_instance_valid(sprite):
				_on_queue_item_completed()
				return
				
			tween.tween_property(sprite, property, start_val + impulse, duration).set_trans(style.transition).set_ease(style.ease)
			tween.tween_property(sprite, property, start_val, duration).set_trans(style.transition).set_ease(style.ease)
			
			tween.finished.connect(func():
				animation_completed.emit(style_id, {"node": node})
				_on_queue_item_completed()
			, CONNECT_ONE_SHOT)
	})

func _get_sprite(node: Node) -> Node2D:
	if node == null: return null
	if node.get("sprite") and is_instance_valid(node.sprite):
		return node.sprite
	return node as Node2D if node is Node2D else null

func _is_animation_inhibited() -> bool:
	return is_reduced_motion_enabled() or should_skip_delays() or _suppress_requests

func _apply_flipping(tween: Tween, sprite: Sprite2D, from: Vector2, to: Vector2) -> void:
	if not is_instance_valid(sprite): return
	var delta_x = to.x - from.x
	if abs(delta_x) > GameConstants.UI.UNIT_SPRITE_FLIP_THRESHOLD:
		var should_flip = delta_x > 0
		tween.tween_callback(func(): sprite.flip_h = should_flip)

func _get_path_points(unit: Node2D, coord: Vector2i) -> Array[Vector2]:
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
	return path_points

func on_unit_moved(index: int, coord: Vector2i) -> void:
	pass

func request_feedback_float(node: Control, offset: Vector2, style_id: StringName = StyleIds.HUD_FEEDBACK, auto_free: bool = true) -> void:
	if not is_instance_valid(node): return
	if _is_animation_inhibited():
		if auto_free:
			node.queue_free()
		return
	if _try_batch("request_feedback_float", [node, offset, style_id, auto_free]): return

	var style: AnimationStyle = _get_style(style_id)
	var duration: float = get_effective_duration(style.duration)
	
	animation_requested.emit(style_id, {"node": node, "offset": offset})
	var tween = _create_tween_for(node)
	if tween == null: return
	
	tween.tween_property(node, "position", node.position + offset + style.position_offset, duration).set_trans(style.transition).set_ease(style.ease)
	
	var f_to: float = float(style.metadata.get("fade_to", 0.0))
	var f_dur: float = get_effective_duration(float(style.metadata.get("fade_duration", style.duration)))
	var f_trans: Tween.TransitionType = style.metadata.get("fade_transition", style.transition) as Tween.TransitionType
	var f_ease: Tween.EaseType = style.metadata.get("fade_ease", style.ease) as Tween.EaseType
	
	tween.parallel().tween_property(node, "modulate:a", f_to, f_dur).set_trans(f_trans).set_ease(f_ease)
	if auto_free: tween.tween_callback(node.queue_free)
	_connect_completion(tween, style_id, {"node": node})

func request_warning_flash(node: Control, style_id: StringName = StyleIds.HUD_WARNING) -> void:
	if not is_instance_valid(node): return
	var style: AnimationStyle = _get_style(style_id)

	if is_reduced_motion_enabled():
		_handle_reduced_motion_flash(node, style, style_id)
		return

	var f_in: float = get_effective_duration(float(style.metadata.get("fade_in_duration", style.duration)))
	var hold: float = get_effective_duration(float(style.metadata.get("hold_duration", 1.0)))
	var f_out: float = get_effective_duration(float(style.metadata.get("fade_out_duration", style.duration)))
	var m_alpha: float = float(style.metadata.get("max_alpha", 1.0))
	var min_a: float = float(style.metadata.get("min_alpha", 0.0))
	var f_out_trans: Tween.TransitionType = style.metadata.get("fade_out_transition", style.transition) as Tween.TransitionType
	var f_out_ease: Tween.EaseType = style.metadata.get("fade_out_ease", style.ease) as Tween.EaseType
	
	animation_requested.emit(style_id, {"node": node})
	var tween = _create_tween_for(node)
	if tween == null: return
	
	tween.tween_property(node, "modulate:a", m_alpha, f_in).set_trans(style.transition).set_ease(style.ease)
	if hold > 0.0: tween.tween_interval(hold)
	tween.tween_property(node, "modulate:a", min_a, f_out).set_trans(f_out_trans).set_ease(f_out_ease)
	tween.tween_callback(node.queue_free)
	_connect_completion(tween, style_id, {"node": node})

func _handle_reduced_motion_flash(node: Control, style: AnimationStyle, style_id: StringName) -> void:
	var total: float = get_effective_duration(float(style.metadata.get("fade_in_duration", style.duration))) + \
					   get_effective_duration(float(style.metadata.get("hold_duration", 1.0))) + \
					   get_effective_duration(float(style.metadata.get("fade_out_duration", style.duration)))
	node.modulate.a = 1.0
	get_tree().create_timer(total).timeout.connect(node.queue_free)
	animation_requested.emit(style_id, {"node": node})
	animation_completed.emit(style_id, {"node": node})

func request_property_animation(target: Object, property: String, value, style_id: StringName = StyleIds.DEFAULT, on_complete: Callable = Callable()) -> void:
	if target == null: return
	if _try_batch("request_property_animation", [target, property, value, style_id, on_complete]): return

	var style: AnimationStyle = _get_style(style_id)
	var duration: float = get_effective_duration(style.duration)
	
	animation_requested.emit(style_id, {"node": target, "property": property, "value": value})
	var tween = _create_tween_for(target)
	if tween == null: return
	
	tween.tween_property(target, property, value, duration).set_trans(style.transition).set_ease(style.ease)
	if on_complete.is_valid(): tween.tween_callback(on_complete)
	_connect_completion(tween, style_id, {"node": target, "property": property})

func _get_style(style_id: StringName) -> AnimationStyle:
	var style: AnimationStyle = _styles.get(style_id)
	if style: return style
	if style_id != StyleIds.DEFAULT:
		GameLogger.warning(GameLogger.Category.UI, "[AnimationRequestService] Missing animation style '%s'. Using default." % [style_id])
	return _default_style

func request_unit_move(unit: Unit, coord: Vector2i) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(_grid): return
	if _is_animation_inhibited():
		unit.position = _grid.map_to_local(coord)
		return
		
	if _try_batch("request_unit_move", [unit, coord]): return
	
	var style: AnimationStyle = _get_style(StyleIds.UNIT_MOVE)
	var path_points: Array[Vector2] = [_grid.map_to_local(coord)]
	
	_enqueue_animation({
		"type": "move",
		"unit": unit,
		"coord": coord,
		"callable": func(): _run_move_animation(unit, path_points, style, coord, StyleIds.UNIT_MOVE)
	})

func _create_tween_for(target: Object) -> Object:
	if _tween_factory and _tween_factory.is_valid():
		return _tween_factory.call(target)
	return target.create_tween()

func _connect_completion(tween, request_id: StringName, payload: Dictionary) -> void:
	if tween == null: return
	if tween.has_signal("finished"):
		tween.finished.connect(func(): animation_completed.emit(request_id, payload), CONNECT_ONE_SHOT)

func set_batch_deferred(deferred: bool) -> void:
	_batch_deferred = deferred
	if not deferred and not _batch_buffer.is_empty(): flush_batch()

func flush_batch() -> void:
	if _batch_buffer.is_empty() or _is_flushing: return
	_is_flushing = true
	var requests = _batch_buffer.get_requests()
	for req in requests:
		if req.type == GameConstants.Anim.TYPE_MOVE:
			_execute_move_animation(req)
		else:
			callv(req.method, req.args)
	_batch_buffer.clear()
	_is_flushing = false

func is_batch_mode_active() -> bool:
	if not _batch_deferred or _is_flushing: return false
	var game_config = GameConfig
	return game_config and game_config.get_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, false)

func _try_batch(method: String, args: Array) -> bool:
	if is_batch_mode_active():
		_batch_buffer.add_generic(method, args)
		return true
	return false

func _prepare_move_data(unit: Node2D, coord: Vector2i, style: AnimationStyle) -> Dictionary:
	return {
		"path_points": _get_path_points(unit, coord),
		"duration": get_effective_duration(style.duration)
	}

func _execute_move_animation(req: Dictionary) -> void:
	var unit: Node2D = req.unit
	if not is_instance_valid(unit): return
	var final_pos = unit.position
	unit.position = req.start_pos # Restore start position for the animation
	_run_move_animation(unit, req.path_points, req.style, req.coord, req.style_id)

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

# Animation Queue Implementation
func _enqueue_animation(item: Dictionary) -> void:
	_animation_queue.append(item)
	if not _is_playing_queue:
		_play_next_in_queue()

func _play_next_in_queue() -> void:
	if _animation_queue.is_empty():
		_is_playing_queue = false
		return
		
	_is_playing_queue = true
	var item = _animation_queue.pop_front()
	var callable: Callable = item.get("callable")
	if callable.is_valid():
		callable.call()
	else:
		_on_queue_item_completed()

func _on_queue_item_completed() -> void:
	_play_next_in_queue()
