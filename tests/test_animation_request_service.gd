extends GdUnitTestSuite


class FakeGrid extends TileMapLayer:
	@warning_ignore("native_method_override")
	func map_to_local(coord: Vector2i) -> Vector2:
		return Vector2(coord.x * 10.0, coord.y * 5.0)

class RecordingTween extends RefCounted:
	signal finished
	var calls: Array[Dictionary] = []

	func tween_property(_target: Object, property: String, value, duration: float) -> RecordingTween:
		calls.append({
			"type": "property",
			"property": property,
			"value": value,
			"duration": duration
		})
		return self

	func tween_interval(duration: float) -> RecordingTween:
		calls.append({"type": "interval", "duration": duration})
		return self

	func parallel() -> RecordingTween:
		calls.append({"type": "parallel"})
		return self

	func set_trans(_value: int) -> RecordingTween:
		return self

	func set_ease(_value: int) -> RecordingTween:
		return self

	func tween_callback(callback: Callable) -> RecordingTween:
		calls.append({"type": "callback"})
		if callback.is_valid():
			callback.call()
		finished.emit()
		return self

func _build_style(style_id: StringName, duration: float, metadata: Dictionary = {}, position_offset: Vector2 = Vector2.ZERO) -> AnimationStyle:
	var style := AnimationStyle.new()
	style.style_id = style_id
	style.duration = duration
	style.metadata = metadata
	style.position_offset = position_offset
	return style

func _make_style_set(styles: Array[AnimationStyle]) -> AnimationStyleSet:
	var anim_set := AnimationStyleSet.new()
	anim_set.styles = styles
	return anim_set

func _make_service(style_set: AnimationStyleSet) -> Dictionary:
	var service := AnimationRequestService.new()
	add_child(service) # Add service to tree so get_tree().root works
	var grid := FakeGrid.new()
	add_child(grid) # Add to scene tree so get_tree() works
	var state := GameState.new({}, [])
	var config := GameSessionBuilder.Config.new()
	config.grid = grid
	config.animation_style_set = style_set
	service.setup(state, config)
	var tweens: Array[RecordingTween] = []
	service.set_tween_factory(func(_target):
		var tween := RecordingTween.new()
		tweens.append(tween)
		return tween
	)
	return {
		"service": service,
		"tweens": tweens
	}

func test_unit_move_request_emits_target_position() -> void:
	var style := _build_style(AnimationRequestService.StyleIds.UNIT_MOVE, 0.4, {}, Vector2(1, 2))
	var bundle := _make_service(_make_style_set([style]))
	var service: AnimationRequestService = bundle["service"]
	var tweens: Array = bundle["tweens"]
	var state_obj := {"emitted": false, "payload": {}}
	service.animation_requested.connect(func(request_id: StringName, data: Dictionary):
		if request_id == AnimationRequestService.StyleIds.UNIT_MOVE:
			state_obj.emitted = true
			state_obj.payload = data.duplicate()
	)
	var unit: Unit = Unit.new()
	service.request_unit_move(unit, Vector2i(2, 3))
	assert_bool(state_obj.emitted).is_true()
	assert_vector(state_obj.payload.get("target_position")).is_equal(Vector2(21, 17))
	assert_int(tweens.size()).is_equal(1)
	var tween_call: Dictionary = tweens[0].calls[0]
	assert_str(tween_call.get("property")).is_equal("position")
	assert_vector(tween_call.get("value")).is_equal(Vector2(21, 17))

func test_warning_flash_uses_style_metadata() -> void:
	var metadata := {
		"fade_in_duration": 0.25,
		"hold_duration": 2.0,
		"fade_out_duration": 0.5,
		"max_alpha": 0.8,
		"min_alpha": 0.2
	}
	var style := _build_style(AnimationRequestService.StyleIds.HUD_WARNING, 0.1, metadata)
	var bundle := _make_service(_make_style_set([style]))
	var service: AnimationRequestService = bundle["service"]
	var tweens: Array = bundle["tweens"]
	var label := Label.new()
	service.request_warning_flash(label)
	assert_int(tweens.size()).is_equal(1)
	var calls: Array = tweens[0].calls
	assert_float(calls[0].get("duration", 0.0)).is_equal_approx(0.25, 0.001)
	assert_float(calls[0].get("value", 0.0)).is_equal_approx(0.8, 0.001)
	assert_str(calls[1].get("type", "")).is_equal("interval")
	assert_float(calls[1].get("duration", 0.0)).is_equal_approx(2.0, 0.001)
	assert_float(calls[2].get("duration", 0.0)).is_equal_approx(0.5, 0.001)
	assert_float(calls[2].get("value", 0.0)).is_equal_approx(0.2, 0.001)

func test_feedback_float_uses_offset_and_fade() -> void:
	var metadata := {"fade_to": 0.3, "fade_duration": 0.8}
	var style := _build_style(AnimationRequestService.StyleIds.HUD_FEEDBACK, 1.2, metadata, Vector2(2, 3))
	var bundle := _make_service(_make_style_set([style]))
	var service: AnimationRequestService = bundle["service"]
	var tweens: Array = bundle["tweens"]
	var label := Control.new()
	service.request_feedback_float(label, Vector2(0, -50))
	assert_int(tweens.size()).is_equal(1)
	var move_call: Dictionary = tweens[0].calls[0]
	assert_vector(move_call.get("value")).is_equal(Vector2(2, -47))
	var fade_call: Dictionary = tweens[0].calls[2]
	assert_float(fade_call.get("value", 0.0)).is_equal_approx(0.3, 0.001)
	assert_float(fade_call.get("duration", 0.0)).is_equal_approx(0.8, 0.001)

func test_property_animation_invokes_callback() -> void:
	var style := _build_style(AnimationRequestService.StyleIds.UNIT_DEATH_ROTATE, 0.5)
	var bundle := _make_service(_make_style_set([style]))
	var service: AnimationRequestService = bundle["service"]
	var tweens: Array = bundle["tweens"]
	var node: Unit = Unit.new()
	var state_obj := {"completed": false}
	service.request_property_animation(node, "rotation_degrees", 45.0, AnimationRequestService.StyleIds.UNIT_DEATH_ROTATE, func(): state_obj.completed = true)
	assert_bool(state_obj.completed).is_true()
	assert_int(tweens.size()).is_equal(1)
	var tween_call: Dictionary = tweens[0].calls[0]
	assert_str(tween_call.get("property")).is_equal("rotation_degrees")

	assert_float(tween_call.get("value", 0.0)).is_equal_approx(45.0, 0.001)
