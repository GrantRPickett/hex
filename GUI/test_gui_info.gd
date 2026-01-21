extends GdUnitTestSuite

const Info := preload("res://GUI/info.gd")

var _info: Info
var _unit: Unit
var _target: Target

func before() -> void:
	_info = auto_free(Info.new())
	_unit = auto_free(Unit.new())
	_target = auto_free(Target.new())

	# Mock the unit for the info panel
	_info._current_unit = _unit

func test_execute_action_directly_with_target() -> void:
	var unit_spy = spy(_unit)
	_info._current_unit = unit_spy

	given(unit_spy.interact(_target)).willReturn(true)
	monitor_signals(_info)

	var action = {
		"type": "interact_test",
		"target": _target
	}

	_info._execute_action_directly(action)

	verify(unit_spy).interact(_target)
	await assert_signal(_info).is_emitted("action_executed", ["interact_test"])

func test_execute_action_directly_wait() -> void:
	monitor_signals(_info)

	var action = {
		"type": "wait"
	}

	_info._execute_action_directly(action)

	await assert_signal(_info).is_emitted("action_executed", ["wait"])