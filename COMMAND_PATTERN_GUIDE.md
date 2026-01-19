# Command Pattern Refactoring - Implementation Guide

## Overview

This document describes the standardized command pattern implementation used throughout the hex game input system. The refactoring improves SOLID principle adherence, testability, and maintainability.

## Architecture

### Core Components

#### 1. GameCommand (Base Class)

**Location:** `input_commands/game_command.gd`

**Responsibility:** Define the command interface and provide validation helpers

**Key Methods:**

- `execute(context: GameCommandContext, payload = null) -> CommandResult`
  - Returns CommandResult instead of void for better error tracking
  - Override in subclasses to implement behavior

- `get_required_context_fields() -> PackedStringArray`
  - Declare dependencies on context fields
  - Empty by default; override to specify requirements

- `validate_context(context: GameCommandContext) -> CommandResult`
  - Helper that validates all required context fields are present
  - Reduces boilerplate in command implementations

**SRP Adherence:** Base class only provides interface and validation scaffolding

#### 2. CommandResult (Value Object)

**Location:** `input_commands/command_result.gd`

**Responsibility:** Communicate command execution success/failure with diagnostic info

**Status Codes:**

- `SUCCESS`: Command executed successfully
- `FAILED`: Generic failure
- `INVALID_CONTEXT`: Missing required dependencies
- `INVALID_PAYLOAD`: Payload validation failed
- `PRECONDITION_FAILED`: Business logic precondition not met

**Usage:**

```gdscript
# Success
return CommandResult.success()

# Failure with diagnostic
return CommandResult.invalid_context(["unit_manager", "camera_controller"])
return CommandResult.invalid_payload("Expected int, got String")
return CommandResult.precondition_failed("Goal already reached")
```

**Benefits:**

- No silent failures - caller knows what went wrong
- Better debugging - error messages indicate the issue
- Testable - tests can verify specific failures

#### 3. CommandValidator (Shared Logic)

**Location:** `input_commands/command_validator.gd`

**Responsibility:** Encapsulate common validation patterns

**Available Validators:**

- `validate_context()` - Check required context fields
- `validate_payload_exists()` - Ensure payload is not null
- `validate_payload_type()` - Verify payload type matches expected
- `validate_payload_dict_keys()` - Check required dictionary keys
- `validate_int()` - Check int is within bounds
- `validate_vector2i_in_bounds()` - Check coordinate is valid

**Benefits:**

- DRY principle - avoid repeating validation code
- Consistent error messages across commands
- OCP - add new validators without modifying commands

#### 4. GameCommandContext (Dependency Container)

**Location:** `input_commands/game_command_context.gd`

**Responsibility:** Aggregate and manage command dependencies

**ISP Improvements:**

- `get_field(field_name: String)` - Query specific field
- Commands declare via `get_required_context_fields()`
- Only dependencies actually needed by the command

**Helper Methods:**

- `is_valid()` - Check all fields are present
- `get_missing_dependencies()` - Diagnostic info
- `get_selected_unit_index()` - Common query
- `get_selected_unit()` - Common query
- `get_grid_dimensions()` - Common query

#### 5. InputCommandRouter (Command Dispatcher)

**Location:** `input_commands/input_command_router.gd`

**Responsibility:** Route named commands to implementations and track results

**Key Changes:**

- `execute()` now returns `CommandResult`
- Logs failures automatically via print_debug
- Validates command exists before executing

```gdscript
var result = router.execute("move_action", "north")
if result.is_failure():
    # Handle error if needed
```

#### 6. CommandFactory (Command Registry)

**Location:** `input_commands/command_factory.gd`

**Responsibility:** Centralize command creation and metadata

**Methods:**

- `create_default_command_set()` - Get all standard commands
- `create_command_by_name()` - Create single command
- `get_command_metadata()` - Get command documentation

**Benefits:**

- Single source of truth for command list
- Metadata enables documentation generation
- Easy to extend with new commands

### Command Implementation Pattern

#### Template

```gdscript
class_name MyCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	# Declare dependencies
	return PackedStringArray(["field1", "field2"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# 1. Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# 2. Validate payload
	if payload == null:
		return CommandResult.invalid_payload("Payload required")

	if not payload is MyPayloadType:
		return CommandResult.invalid_payload("Expected MyPayloadType")

	# 3. Check preconditions
	if some_precondition_fails():
		return CommandResult.precondition_failed("Reason why")

	# 4. Execute
	context.some_field.some_method()

	# 5. Return success
	return CommandResult.success()
```

#### Rules

1. **Always declare dependencies** via `get_required_context_fields()`
2. **Validate in order:** context → payload → preconditions → execute
3. **Return specific error codes** not generic failures
4. **No side effects on validation failure** - only execute if all checks pass
5. **No null-coalescing or silent returns** - explicit error handling

## SOLID Principles Adherence

### Single Responsibility

- **GameCommand:** Define interface and validation contract only
- **Individual Commands:** Implement specific game action
- **CommandValidator:** Encapsulate validation logic
- **CommandFactory:** Manage command creation and metadata
- **InputCommandRouter:** Route commands, not validate them

### Open/Closed

- Add new validators to `CommandValidator` without modifying commands
- Add new commands without modifying router
- Extend `GameCommand` for new command patterns
- Metadata in `CommandFactory` enables extensibility

### Liskov Substitution

- All commands follow same `execute()` contract: returns `CommandResult`
- `get_required_context_fields()` enables runtime substitutability
- Commands can be swapped for mocks/test doubles in router

### Interface Segregation

- Context fields can be queried individually
- Commands declare only fields they need
- No command forced to depend on unneeded context

### Dependency Inversion

- Commands depend on `GameCommandContext` (abstraction)
- Context aggregates services but commands don't know their types
- Easy to swap service implementations for testing

## Testing Strategy

### Unit Test Pattern

```gdscript
# Create mock context with only required fields
var context = GameCommandContext.new(
	mock_unit_manager,
	mock_hex_navigator,
	null,  # Don't need camera controller
	null,  # Don't need move controller
	mock_turn_controller,
	null,  # Don't need goal controller
	null   # Don't need grid
)

# Test success
var result = command.execute(context, "north")
assert(result.is_success())
assert(mock_move_controller.request_move_called)

# Test validation failure
var bad_payload_result = command.execute(context, 123)  # Wrong type
assert(bad_payload_result.is_failure())
assert(bad_payload_result.status == CommandResult.Status.INVALID_PAYLOAD)

# Test precondition failure
mock_goal_controller.is_goal_reached.return_value = true
var precond_result = command.execute(context, null)
assert(precond_result.status == CommandResult.Status.PRECONDITION_FAILED)
```

## Migration Guide

### Old Pattern

```gdscript
func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or context.field1 == null or context.field2 == null:
		return
	# ...execute logic
```

### New Pattern

```gdscript
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["field1", "field2"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	var result = validate_context(context)
	if result.is_failure():
		return result
	# ...execute logic
	return CommandResult.success()
```

## Common Patterns

### Validate Payload Dictionary

```gdscript
var dict_result = CommandValidator.validate_payload_dict_keys(
	payload,
	PackedStringArray(["x", "y"])
)
if dict_result.is_failure():
	return dict_result
```

### Validate Coordinate In Bounds

```gdscript
var coord: Vector2i = calculate_coordinate()
var bounds_result = CommandValidator.validate_vector2i_in_bounds(
	coord,
	grid_width,
	grid_height
)
if bounds_result.is_failure():
	return bounds_result
```

### Conditional Validation

```gdscript
# Only validate camera controller if we need it
if needs_camera:
	if context.camera_controller == null:
		return CommandResult.invalid_context(["camera_controller"])
```

## Performance Considerations

- `CommandResult` is RefCounted (lightweight, garbage collected)
- Validation is O(n) where n = number of required fields (~3-5 typically)
- Router lookup is O(1) dictionary access
- No string matching or reflection used

## Error Logging

The router automatically logs all failures via `print_debug()`:

```
DBG Command 'move_action' failed: INVALID_CONTEXT: missing unit_manager
DBG Command 'select_index' failed: INVALID_PAYLOAD: Expected int, got String
DBG Command 'wait' failed: PRECONDITION_FAILED: Move is locked
```

Enable debug logging in Godot to see these messages during development.

## Future Enhancements

1. **Command History** - Store CommandResult history for undo/replay
2. **Macros** - Execute sequences of commands atomically
3. **Async Commands** - Support async execute with await
4. **Command Priorities** - Queue high-priority commands
5. **Event System** - Emit signals on command execution
6. **Replay System** - Record and replay command sequences
7. **Telemetry** - Track command usage statistics

## Checklist for New Commands

- [ ] Extends `GameCommand`
- [ ] Implements `get_required_context_fields()`
- [ ] Validates context first
- [ ] Validates payload with specific error messages
- [ ] Checks preconditions before execution
- [ ] Returns appropriate `CommandResult`
- [ ] Added to `CommandFactory.create_default_command_set()`
- [ ] Metadata added to `CommandFactory.get_command_metadata()`
- [ ] Unit tests created with mock context
- [ ] Tests for: success, context failures, payload failures, precondition failures
