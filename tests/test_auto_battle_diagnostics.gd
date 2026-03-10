extends GdUnitTestSuite


class FakeHud extends Node:
	var messages: Array[String] = []

	func show_warning_message(text: String) -> void:
		messages.append(text)

func test_report_unsupported_actions_records_history() -> void:
	AutoBattleDiagnostics._unsupported_history.clear()
	var unit: Variant = auto_free(Unit.new())
	unit.unit_name = "Scout"
	var hud := FakeHud.new()
	
	var move_action = auto_free(UnitAction.new(UnitAction.Type.MOVE))
	var gather_action = auto_free(UnitAction.new(UnitAction.Type.GATHER))
	
	var actions: Array[UnitAction] = [
		gather_action,
		move_action
	]
	var summary: Dictionary = AutoBattleDiagnostics.report_unsupported_actions(unit, actions, hud)
	assert_bool(summary.get("has_supported", false)).is_true()
	var warnings: Array = summary.get("warnings", [])
	assert_array(warnings).has_size(1)
	assert_str(warnings[0].get("action_type")).is_equal("gather")
	assert_int(AutoBattleDiagnostics.get_unsupported_history().size()).is_equal(1)
	assert_int(hud.messages.size()).is_equal(1)
