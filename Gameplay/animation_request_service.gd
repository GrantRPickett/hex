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

func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
	_grid = config.grid
	_unit_manager = state.unit_manager
	_default_style.style_id = StyleIds.DEFAULT
	_default_style.duration = 0.2
	_default_style.transition = Tween.TRANS_SINE
	_default_style.ease = Tween.EASE_OUT
	_styles.clear()
	var style_set = config.animation_style_set # Access style_set from config
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

func request_unit_move(unit: Node2D, coord: Vector2i, style_id: StringName = StyleIds.UNIT_MOVE) -> void:
	if not is_instance_valid(unit):
		return
	var style: AnimationStyle = _get_style(style_id)

	var path_points: Array[Vector2] = []
	var use_path := false

	if is_instance_valid(_grid) and unit.has_method("has_tentative_move") and unit.movement.has_tentative_move():
		var tentative_path = unit.movement.get_tentative_path()
		var idx = tentative_path.find(coord)
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
	var duration = _get_effective_duration(style.duration)

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
		tween.tween_property(unit, "position", step_target, duration).set_trans(style.transition).set_ease(style.ease)

	_connect_completion(tween, style_id, {"unit": unit, "coord": coord})

func on_unit_moved(index: int, coord: Vector2i) -> void:
	if not _unit_manager:
		return
	var unit = _unit_manager.get_unit(index)
	if unit:
		request_unit_move(unit, coord)

func request_feedback_float(node: Control, offset: Vector2, style_id: StringName = StyleIds.HUD_FEEDBACK, auto_free: bool = true) -> void:
	if not is_instance_valid(node):
		return
	var style: AnimationStyle = _get_style(style_id)
	var duration = _get_effective_duration(style.duration)
	animation_requested.emit(style_id, {
		"node": node,
		"offset": offset
	})
	var tween: Tween = _create_tween_for(node)
	if tween == null:
		return
	tween.tween_property(node, "position", node.position + offset + style.position_offset, duration).set_trans(style.transition).set_ease(style.ease)
	var fade_to: float = float(style.metadata.get("fade_to", 0.0))
	var fade_duration: float = _get_effective_duration(float(style.metadata.get("fade_duration", style.duration)))
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
	var fade_in: float = _get_effective_duration(float(style.metadata.get("fade_in_duration", style.duration)))
	var hold: float = _get_effective_duration(float(style.metadata.get("hold_duration", 1.0)))
	var fade_out: float = _get_effective_duration(float(style.metadata.get("fade_out_duration", style.duration)))
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
	var duration = _get_effective_duration(style.duration)
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
		push_warning("[AnimationRequestService] Missing animation style '%s'. Using default." % [style_id])
	return _default_style

func _create_tween_for(target: Object) -> Object:
	if _tween_factory and _tween_factory.is_valid():
		var created = _tween_factory.call(target)
		return created
	return target.create_tween()

func _connect_completion(tween: Tween, request_id: StringName, payload: Dictionary) -> void:
	if tween == null:
		return
	if tween.has_signal("finished"):
		tween.finished.connect(func():
			animation_completed.emit(request_id, payload)
		, CONNECT_ONE_SHOT)

func _get_effective_duration(base_duration: float) -> float:
	var multiplier := 1.0
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config:
		var speed = game_config.get_value("gameplay/animation_speed", "normal")
		match speed:
			"fast": multiplier = 0.5
			"skip": multiplier = 0.0
	return base_duration * multiplier
