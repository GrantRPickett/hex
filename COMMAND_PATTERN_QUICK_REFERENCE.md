# Command Pattern - Quick Reference

## For Adding a New Command

### 1. Create the Command Class

```gdscript
class_name MyNewCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["field1", "field2"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	if payload == null:
		return CommandResult.invalid_payload("Payload required")

	# Check preconditions
	if not can_execute():
		return CommandResult.precondition_failed("Reason")

	# Execute
	context.field1.do_something(payload)
	return CommandResult.success()
```

### 2. Register in CommandFactory

Add to `create_default_command_set()`:
```gdscript
"my_command": MyNewCommand.new(),
```

Add to `create_command_by_name()`:
```gdscript
"MyNewCommand": return MyNewCommand.new()
```

Add metadata to `get_command_metadata()`:
```gdscript
"my_command": {
	"description": "What this does",
	"required_context": ["field1", "field2"],
	"payload_type": "String",
	"payload_description": "What payload means"
}
```

### 3. Use in InputController

Already integrated! Just wire up signals to call:
```gdscript
_execute_command("my_command", payload)
```

## For Validating Commands

### Check Success
```gdscript
var result = command.execute(context, payload)
if result.is_success():
	# Do something
```

### Check Specific Failure
```gdscript
if result.status == CommandResult.Status.INVALID_CONTEXT:
	print("Missing dependencies: ", result.error_message)
elif result.status == CommandResult.Status.INVALID_PAYLOAD:
	print("Bad payload: ", result.error_message)
elif result.status == CommandResult.Status.PRECONDITION_FAILED:
	print("Condition not met: ", result.error_message)
```

### Get Description
```gdscript
print(result.get_description())  # e.g., "INVALID_PAYLOAD: Expected int, got String"
```

## For Testing Commands

```gdscript
# Create minimal context
var context = GameCommandContext.new(
	unit_manager_mock,  # Only include what you need
	null, null, null,   # Rest can be null
	turn_controller_mock,
	null, null
)

# Create command
var cmd = MyCommand.new()

# Test success
var result = cmd.execute(context, valid_payload)
assert(result.is_success())

# Test failure
var bad_result = cmd.execute(context, invalid_payload)
assert(bad_result.is_failure())
assert(bad_result.status == CommandResult.Status.INVALID_PAYLOAD)
```

## Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| `SUCCESS` | Executed successfully | Command completed |
| `FAILED` | Generic failure | Unexpected error |
| `INVALID_CONTEXT` | Missing dependencies | "missing unit_manager" |
| `INVALID_PAYLOAD` | Bad input data | "Expected String, got int" |
| `PRECONDITION_FAILED` | Business logic block | "Goal already reached" |

## Common Validators

```gdscript
# Context validation (automatic via validate_context())
CommandValidator.validate_context(context, required_fields)

# Payload exists
CommandValidator.validate_payload_exists(payload)

# Payload type
CommandValidator.validate_payload_type(payload, "String")

# Dict keys
CommandValidator.validate_payload_dict_keys(payload, PackedStringArray(["x", "y"]))

# Int bounds
CommandValidator.validate_int(value, -10, 10, "index")

# Coordinate bounds
CommandValidator.validate_vector2i_in_bounds(coord, width, height)
```

## Context Fields Available

| Field | Type | Usage |
|-------|------|-------|
| `unit_manager` | UnitManager | Units, selection |
| `hex_navigator` | HexNavigator | Direction mapping |
| `camera_controller` | CameraController | Camera control |
| `move_controller` | MoveController | Movement requests |
| `turn_controller` | TurnController | Turn validation |
| `goal_controller` | GoalController | Goal state |
| `grid` | Node2D | Grid coordinates |

## Router Usage

```gdscript
# Create context
var context = GameCommandContext.new(...)

# Create router
var router = InputCommandRouter.new(context)
router.set_commands(CommandFactory.create_default_command_set())

# Execute
var result = router.execute("command_name", payload)

# Check result
if result.is_failure():
	print_debug("Failed: ", result.get_description())
```

## Dependency Declaration Pattern

Always declare your dependencies:

```gdscript
# Good: Clear what this command needs
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "move_controller"])

# Bad: Depends on everything
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([...all 7 fields...])

# Bad: No declaration
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([])
```

## Anti-Patterns to Avoid

### ❌ Silent Failures
```gdscript
if context == null:
	return  # Silent - nobody knows what went wrong
```

### ✅ Explicit Errors
```gdscript
if context == null:
	return CommandResult.invalid_context(["context"])
```

### ❌ Unchecked Payload
```gdscript
var my_int = payload  # Crashes if payload is wrong type
```

### ✅ Validated Payload
```gdscript
if not payload is int:
	return CommandResult.invalid_payload("Expected int")
var my_int = payload
```

### ❌ No Dependency Declaration
```gdscript
# What does this command need?
func execute(context, payload):
	context.unit_manager...
```

### ✅ Clear Declaration
```gdscript
func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager"])
```

## Debugging Commands

Enable debug logging to see failures:
```
DBG Command 'move_action' failed: INVALID_CONTEXT: missing camera_controller
DBG Command 'wait' failed: PRECONDITION_FAILED: Move is locked
```

Check router logs if commands silently don't execute.

## File Structure

```
Gameplay/input_commands/
├── game_command.gd (base class)
├── game_command_context.gd (dependencies)
├── command_result.gd (success/failure)
├── command_validator.gd (validation utilities)
├── command_factory.gd (creation & metadata)
├── input_command_router.gd (dispatcher)
│
└── Individual Commands:
	├── move_action_command.gd
	├── select_index_command.gd
	├── wait_command.gd
	├── primary_action_command.gd
	├── joy_move_command.gd
	├── selection_cycle_command.gd
	├── toggle_free_cam_command.gd
	└── zoom_camera_command.gd
```

## Documentation Files

- `COMMAND_PATTERN_GUIDE.md` - Comprehensive architecture guide
- `COMMAND_PATTERN_ANALYSIS.md` - Problem analysis and rationale
- `COMMAND_REFACTORING_SUMMARY.md` - What was changed and why
