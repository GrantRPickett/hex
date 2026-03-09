# Command Pattern Usage Analysis & Missing Commands

## Current Status

### ✅ Commands Currently Implemented & Used

| Command | Input Source | Triggered By | Used In | Status |
|---------|--------------|--------------|---------|--------|
| `move_action` | Keyboard/Gamepad | Move key press | InputHandler → InputController → MoveController | ✅ Active |
| `joy_move` | Gamepad analog | Joystick axis | InputHandler → InputController → MoveController | ✅ Active |
| `primary_action` | Mouse/Touch | Left-click/tap | InputHandler → InputController → MoveController.request_move_to_coord() | ✅ Active |
| `select_index` | Keyboard | Direct unit selection | InputHandler → InputController | ✅ Active |
| `selection_cycle` | Keyboard | Cycle units | InputHandler → InputController | ✅ Active |
| `wait` | Keyboard | End turn | InputHandler → InputController → TurnController | ✅ Active |
| `toggle_free_cam` | Keyboard | Camera toggle | InputHandler → InputController → CameraController | ✅ Active |
| `zoom_camera` | Mouse wheel | Zoom in/out | InputHandler → InputController → CameraController | ✅ Active |

## ❌ Missing Commands - Action Menu Execution

The Info panel (GUI) displays available actions but **directly calls Unit methods instead of using commands**:

### Actions Not Yet Implemented as Commands

1. **Attack Command** ❌ MISSING
   - **Location:** [info.gd](../../GUI/info.gd#L123)
   - **Current:** `_current_unit.attack_unit(action.targets[0])`
   - **Should Be:** Command: `attack_unit`
   - **Payload:** `{ "target_unit": target_unit }`
   - **Context Needed:** `unit_manager`, `turn_controller`
   - **Used By:** Info panel button press
   - **Also Used By:** AI Controller (direct call)

2. **Aid Ally Command** ❌ MISSING
   - **Location:** [info.gd](../../GUI/info.gd#L129)
   - **Current:** `_current_unit.aid_ally(action.targets[0])`
   - **Should Be:** Command: `aid_ally`
   - **Payload:** `{ "target_unit": target_unit }`
   - **Context Needed:** `unit_manager`, `turn_controller`
   - **Used By:** Info panel button press
   - **Also Used By:** AI Controller (direct call)

3. **Work on Goal Command** ❌ MISSING
   - **Location:** [info.gd](../../GUI/info.gd#L135)
   - **Current:** `_current_unit.work_on_goal(goal)`
   - **Should Be:** Command: `work_on_goal`
   - **Payload:** `{ "goal_index": goal_index }`
   - **Context Needed:** `unit_manager`, `goal_manager`, `turn_controller`
   - **Used By:** Info panel button press
   - **Also Used By:** AI Controller (direct call)

4. **Loot Command** ❌ MISSING
   - **Location:** [info.gd](../../GUI/info.gd#L141)
   - **Current:** `_current_unit.loot(loot_coord)`
   - **Should Be:** Command: `loot`
   - **Payload:** `{ "loot_coord": loot_coord }`
   - **Context Needed:** `unit_manager`, `loot_manager`, `turn_controller`
   - **Used By:** Info panel button press

## Architecture Gap

### Current Flow
```
Input (Keyboard/Mouse)
	↓
InputHandler (emits signal)
	↓
InputController (routes to commands)
	↓
Commands (execute)
	↓
Game State (Unit position, selection, etc.)
```

### Missing Flow for Actions
```
Info Panel (displays available actions)
	↓
User clicks action button
	↓
Info._on_action_button_pressed()
	↓
DIRECT CALL: unit.attack_unit(target) ❌ Bypasses commands!
	↓
Unit state changes
```

### What Should Happen
```
Info Panel (displays available actions)
	↓
User clicks action button
	↓
Info emits signal / calls InputController
	↓
InputController._execute_command() ✅
	↓
Command validates & executes
	↓
Unit state changes
```

## Root Cause Analysis

The action menu was implemented before the command pattern was standardized. It directly manipulates Unit methods rather than going through the command routing system.

### Why This Matters

1. **Inconsistent Error Handling** - Actions can fail silently
2. **Untraceable Execution** - No logging of what actions were attempted
3. **Testing Difficulty** - Can't mock or test action execution paths
4. **Future Features** - Undo/replay/macros won't capture these actions
5. **Command Pattern Incomplete** - System only handles movement/navigation, not game actions

## Files Affected

### Need Command Creation
- `attack_unit_command.gd` (NEW)
- `aid_ally_command.gd` (NEW)
- `work_on_goal_command.gd` (NEW)
- `loot_command.gd` (NEW)

### Need Integration Updates
- [info.gd](../../GUI/info.gd) - Route through InputController instead of direct calls
- [command_factory.gd](../input_commands/command_factory.gd) - Register new commands
- [input_controller.gd](../input_controller.gd) - Expose action method

### Need Minor Updates
- [move_controller.gd](../move_controller.gd) - Already calling info.update_available_actions(), no change needed
- [unit.gd](../unit.gd) - No changes needed (commands will call existing methods)

## Detailed Implementation Plan

### 1. Create AttackUnitCommand

```gdscript
class_name AttackUnitCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["attacker_index", "target_index"])
	)
	if payload_result.is_failure():
		return payload_result

	var attacker_idx = payload.get("attacker_index", -1)
	var target_idx = payload.get("target_index", -1)

	# Validate indices
	var attacker = context.unit_manager.get_unit(attacker_idx)
	var target = context.unit_manager.get_unit(target_idx)

	if attacker == null or target == null:
		return CommandResult.invalid_payload("Invalid unit indices")

	# Check preconditions
	if not context.turn_controller.can_act_on_index(attacker_idx):
		return CommandResult.precondition_failed("Unit cannot act")

	if not attacker.has_action_available():
		return CommandResult.precondition_failed("Unit has no actions")

	if not attacker.get_adjacent_units([target]).has(target):
		return CommandResult.precondition_failed("Target not adjacent")

	# Execute
	attacker.attack_unit(target)
	return CommandResult.success()
```

### 2. Create AidAllyCommand (Similar pattern)

### 3. Create WorkOnGoalCommand

### 4. Create LootCommand

### 5. Update Info Panel

```gdscript
# Instead of:
_current_unit.attack_unit(action.targets[0])

# Do:
InputController._execute_command("attack_unit", {
	"attacker_index": _current_unit_index,
	"target_index": unit_manager.get_unit_index(action.targets[0])
})
```

## Validation Against Game Mechanics

### Checking UnitActionManager Against Commands

**Unit can perform these actions:**
- ✅ Move (command exists)
- ❌ Attack adjacent enemy (missing command)
- ❌ Aid adjacent ally (missing command)
- ❌ Work on goal at current position (missing command)
- ❌ Loot at current position (missing command)
- ✅ Wait/End Turn (command exists)

### Checking AI Controller Against Commands

The AI already uses these actions:
- ✅ Move (via MoveController)
- ✅ Attack (direct call to `ai_unit.attack_unit()`)
- ✅ Aid (direct call to `ai_unit.aid_ally()`)
- ✅ Work on Goal (direct call to `ai_unit.work_on_goal()`)

**Why AI calling direct methods is OK for now:**
- AI makes decisions autonomously
- Doesn't need player input validation
- Could be refactored later to use same commands with different validation

## Integration Priority

### High Priority (Blocks Player Actions)
1. AttackUnitCommand - Combat is core mechanic
2. WorkOnGoalCommand - Goal completion is core mechanic
3. LootCommand - Resource management

### Medium Priority
4. AidAllyCommand - Support mechanic

### Implementation Order

1. Create all 4 command classes
2. Update CommandFactory with new commands
3. Update Info panel to route through InputController
4. Test each action through Info panel
5. Verify error handling works
6. Add unit tests

## Summary

**Status:** Command pattern is 67% complete
- ✅ Input/Navigation commands: 8/8 (100%)
- ❌ Action commands: 0/4 (0%)

**Gap:** Action menu bypasses command system entirely, causing inconsistent error handling and making the pattern incomplete.

**Solution:** Create 4 missing command classes and integrate Info panel routing.

**Effort:** ~2-3 hours to implement and integrate all 4 commands.
