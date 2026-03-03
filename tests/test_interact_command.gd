extends GdUnitTestSuite

var _command: InteractCommand
var _context: GameCommandContext

func before() -> void:
	_command = InteractCommand.new()
	_context = mock(GameCommandContext)

func test_get_required_context_fields() -> void:
	var fields = _command.get_required_context_fields()
	assert_array(fields).contains(["unit_manager"])

func test_execute_no_unit_selected() -> void:
	_context.given(_context.has_context("unit_manager")).is_true()
	_context.given(_context.get_selected_unit()).willReturn(null)

	var result = _command.execute(_context, null)

	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_description()).contains("No unit selected")

func test_execute_invalid_payload() -> void:
	var unit = auto_free(Unit.new())
	_context.given(_context.has_context("unit_manager")).is_true()
	_context.given(_context.get_selected_unit()).willReturn(unit)

	var result = _command.execute(_context, "invalid_payload")

	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_description()).contains("Payload must be a valid Target")

func test_execute_interaction_success() -> void:
	var unit = auto_free(Unit.new())
	var target = auto_free(Target.new())

	var unit_spy = spy(unit)
	_context.given(_context.has_context("unit_manager")).is_true()
	_context.given(_context.get_selected_unit()).willReturn(unit_spy)

	_context.given(unit_spy.interaction.interaction.interact(target)).willReturn(true)

	var result = _command.execute(_context, target)

	assert_bool(result.is_success()).is_true()
	verify(unit_spy).interaction.interaction.interact(target)

func test_execute_interaction_failure() -> void:
	var unit = auto_free(Unit.new())
	var target = auto_free(Target.new())

	var unit_spy = spy(unit)
	_context.given(_context.has_context("unit_manager")).is_true()
	_context.given(_context.get_selected_unit()).willReturn(unit_spy)

	_context.given(unit_spy.interaction.interaction.interact(target)).willReturn(false)

	var result = _command.execute(_context, target)

	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_description()).contains("Interaction failed")
	verify(unit_spy).interaction.interaction.interact(target)