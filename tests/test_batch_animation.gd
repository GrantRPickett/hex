extends GdUnitTestSuite

const AnimService := preload("res://Gameplay/animation_request_service.gd")

var _svc: AnimService
var _original_speed

func before_test() -> void:
	_svc = AnimService.new()
	var state = GameState.new({})
	var config = GameSessionBuilder.Config.new()
	_svc.setup(state, config)
	add_child(_svc)
	
	if GameConfig:
		GameConfig.set_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, true)

func after_test() -> void:
	if GameConfig:
		GameConfig.set_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, false)
	if is_instance_valid(_svc):
		_svc.queue_free()

func test_batch_buffering_moves() -> void:
	var unit = auto_free(Node2D.new()) # AnimService uses Node2D for move requests internally or checks unit as Unit
	# Actually, AnimService.request_unit_move expects a Unit
	var fake_unit = auto_free(Unit.new())
	add_child(fake_unit)
	
	# Enable batching deferred flag
	_svc.set_batch_deferred(true)
	
	var monitor = monitor_signals(_svc)
	_svc.request_unit_move(fake_unit, Vector2i(1, 1))
	
	# Should be buffered, NOT emitted
	assert_bool(_svc._batch_buffer.is_empty()).is_false()
	assert_signal(monitor).is_not_emitted("animation_requested")
	
	# Flush
	_svc.flush_batch()
	assert_bool(_svc._batch_buffer.is_empty()).is_true()
	assert_signal(monitor).is_emitted("animation_requested")

func test_batch_deferred_toggle_auto_flushes() -> void:
	var fake_unit = auto_free(Unit.new())
	add_child(fake_unit)
	
	_svc.set_batch_deferred(true)
	_svc.request_unit_move(fake_unit, Vector2i(1, 1))
	
	var monitor = monitor_signals(_svc)
	_svc.set_batch_deferred(false) # Setting to false should flush
	
	assert_bool(_svc._batch_buffer.is_empty()).is_true()
	assert_signal(monitor).is_emitted("animation_requested")

func test_batch_works_for_feedback_float() -> void:
	var label = auto_free(Label.new())
	add_child(label)
	
	_svc.set_batch_deferred(true)
	var monitor = monitor_signals(_svc)
	_svc.request_feedback_float(label, Vector2(0, -50))
	
	assert_bool(_svc._batch_buffer.is_empty()).is_false()
	assert_signal(monitor).is_not_emitted("animation_requested")
	
	_svc.flush_batch()
	assert_signal(monitor).is_emitted("animation_requested")

func test_batch_ignored_if_toggle_off() -> void:
	GameConfig.set_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, false)
	_svc.set_batch_deferred(true) # Even if deferred is true, if toggle is off, it should NOT buffer
	
	var fake_unit = auto_free(Unit.new())
	add_child(fake_unit)
	
	var monitor = monitor_signals(_svc)
	_svc.request_unit_move(fake_unit, Vector2i(1, 1))
	
	assert_bool(_svc._batch_buffer.is_empty()).is_true()
	assert_signal(monitor).is_emitted("animation_requested")
