extends GdUnitTestSuite

class FakeTurnController extends TurnController:
	var locked := false

	func is_player_auto_control_locked() -> bool:
		return locked

class FakeHud extends Node:
	var messages: Array[String] = []

	func show_warning_message(text: String) -> void:
		messages.append(text)

func test_undo_blocked_when_auto_battle_locked() -> void:
	var data := _create_controller()
	var controller: InputController = data.controller
	var turn: FakeTurnController = data.turn
	var hud: FakeHud = data.hud
	turn.locked = true
	var undo_calls := 0
	controller.undo_requested.connect(func(): undo_calls += 1)
	var event := InputEventAction.new()
	event.action = &"ui_undo"
	event.pressed = true
	controller._unhandled_input(event)
	assert_int(undo_calls).is_equal(0)
	assert_array(hud.messages).has_size(1)

func test_undo_emits_when_auto_battle_unlocked() -> void:
	var data := _create_controller()
	var controller: InputController = data.controller
	var turn: FakeTurnController = data.turn
	var hud: FakeHud = data.hud
	turn.locked = false
	var undo_calls := 0
	controller.undo_requested.connect(func(): undo_calls += 1)
	var event := InputEventAction.new()
	event.action = &"ui_undo"
	event.pressed = true
	controller._unhandled_input(event)
	assert_int(undo_calls).is_equal(1)
	assert_array(hud.messages).is_empty()

func _create_controller() -> Dictionary:
	var controller: InputController = auto_free(InputController.new())
	get_tree().root.add_child(controller)
	var hud: Variant = auto_free(FakeHud.new())
	get_tree().root.add_child(hud)
	var turn := FakeTurnController.new()
	controller._turn_controller = turn
	controller._hud = hud
	return {"controller": controller, "turn": turn, "hud": hud}
