extends GdUnitTestSuite

const GameSessionScript := preload("res://Gameplay/game_session.gd")

class FakeTurnSystem extends TurnSystem:
	var side = GameConstants.Side.PLAYER # 1
	func get_current_side() -> int: return side

class FakeTurnController extends TurnController:
	var enabled_state := true
	var ts: FakeTurnSystem = FakeTurnSystem.new()
	var triggered_next := false

	func get_turn_system() -> FakeTurnSystem:
		return ts

	func set_enabled(value: bool) -> void:
		enabled_state = value

	func start_next_turn() -> void:
		triggered_next = true

class FakeInputHandler extends InputHandler:
	var reset_joy := false
	var processing := true
	func reset_joy_state() -> void:
		reset_joy = true
	@warning_ignore("native_method_override")
	func set_process_unhandled_input(val: bool) -> void:
		processing = val

class FakeMoveController extends MoveController:
	var physics := true
	@warning_ignore("native_method_override")
	func set_physics_process(val: bool) -> void:
		physics = val

func test_game_session_handle_pause_state_changed() -> void:
	var config := GameSessionBuilder.Config.new()
	var sess := GameSessionScript.new(config)
	var state := GameState.new({})
	var tc := FakeTurnController.new()
	state.turn_controller = tc
	sess.state = state

	# Pause
	sess.handle_pause_state_changed(true)
	assert_bool(tc.enabled_state).is_false()
	assert_bool(tc.triggered_next).is_false()

	# Unpause (player turn)
	sess.handle_pause_state_changed(false)
	assert_bool(tc.enabled_state).is_true()
	assert_bool(tc.triggered_next).is_false() # Should not trigger next_turn on player

	# Unpause (neutral turn)
	tc.ts.side = GameConstants.Side.NEUTRAL # 0
	sess.handle_pause_state_changed(false)
	assert_bool(tc.triggered_next).is_true()

	tc.queue_free()

func test_game_session_disable_gameplay() -> void:
	var config := GameSessionBuilder.Config.new()
	var input := FakeInputHandler.new()
	config.input_handler = input

	var sess := GameSessionScript.new(config)
	var state := GameState.new({})
	var move := FakeMoveController.new()
	state.move_controller = move
	sess.state = state

	sess.disable_gameplay()

	assert_bool(input.reset_joy).is_true()
	assert_bool(input.processing).is_false()
	assert_bool(move.physics).is_false()

	input.queue_free()
	move.queue_free()
