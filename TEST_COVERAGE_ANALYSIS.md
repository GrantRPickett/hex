# Test Coverage Gap Analysis

## Summary

**Total Missing Test References: 44 functions**

The coverage checker identified 44 functions that lack references in test files. These fall into clear, testable categories that can be addressed systematically.

---

## Coverage by Category

### 1. **Input Command Classes (20 functions) — HIGH PRIORITY**
**Impact:** 45% of missing coverage

Command pattern is highly standardized. All command classes need:
- `get_required_context_fields()` implementations
- `command_result.gd` query methods (`is_success()`, `is_failure()`, `get_description()`)
- `game_command_context.gd` accessor methods
- `validate_context()` base logic

**Files Affected:**
- `command_result.gd`: `is_success()`, `is_failure()`, `get_description()`
- `game_command.gd`: `get_required_context_fields()`, `validate_context()`
- `game_command_context.gd`: `get_field()`, `get_grid_dimensions()`, `get_selected_unit_index()`
- 10 command subclasses: each needs `get_required_context_fields()`

**Strategy:** Consolidate into single `test_game_command_hierarchy.gd` with parameterized tests for all command types.

**Existing Foundation:**
- `test_input_commands.gd` (57 lines) — basic framework exists
- `test_action_commands.gd` — patterns for command validation

---

### 2. **Unit & Unit Manager (13 functions) — MEDIUM-HIGH PRIORITY**
**Impact:** 30% of missing coverage

Core gameplay logic: unit state management, goal interaction, loot handling, consumables.

**Unit Functions (8):**
- Setters: `set_loot_manager()`, `set_goal_manager()`, `set_combat_system()`
- Logic: `work_on_goal()`, `get_path_to_coord()`, `loot()`, `apply_consumable()`
- Lifecycle: `prepare_for_save()`

**UnitManager Functions (5):**
- Accessors: `get_selected_sprite()`, `set_coord()`, `set_player_controlled()`
- Goal state: `set_goal_reached()`, `are_all_goals_reached()`

**UnitController Functions (2):**
- Setters: `set_coord()`, `set_player_controlled()`

**Strategy:** Create `test_unit_dependency_injection.gd` (pure setters) and extend `test_unit_system.gd` with goal/loot logic.

**Existing Foundation:**
- `test_unit_system.gd` — unit creation and basic logic
- `test_unit_manager.gd` — manager structure exists

---

### 3. **Goal & Movement Management (9 functions) — MEDIUM PRIORITY**
**Impact:** 20% of missing coverage

**Goal Manager (4 functions):**
- Accessors: `get_target()`, `set_target()`, `get_targets()`, `get_goal_node()`

**Move Controller (1 function):**
- `request_move_to_coord()`

**Gameplay Integration (2 functions):**
- `set_unit_controlled_by_player()`, `set_goal_coord()`

**AI Controller (1 function):**
- `execute_turn()`

**Strategy:** Extend `test_goal_manager.gd` with accessor methods; create `test_ai_controller.gd` for AI turn execution.

**Existing Foundation:**
- `test_goal_manager.gd` (50 lines) — basic manager tests
- `test_turn_flow_with_ai.gd` — integration context

---

### 4. **GUI Update (1 function) — LOW PRIORITY**
**Impact:** 2% of missing coverage

**GUI/info.gd:**
- `update_available_actions()`

**Strategy:** Extend `test_controls_menu.gd` or create `test_gui_info.gd` with signal-based assertions.

---

## Implementation Strategy

### Phase 1: High-Volume Gaps (Commands & Getters)
Create `test_command_system_coverage.gd`:
- Test all `CommandResult` query methods
- Test `GameCommandContext` accessors with real and stub dependencies
- Parameterized tests for 10 command subclasses
- **Estimated effort:** 2 hours, **Coverage gained:** 20 functions

### Phase 2: Unit State Management
Extend existing test files:
- Add `test_unit_dependency_injection.gd` for setter coverage
- Extend `test_unit_manager.gd` with goal/sprite state queries
- Add goal-reaching assertions to `test_goal_manager.gd`
- **Estimated effort:** 1.5 hours, **Coverage gained:** 13 functions

### Phase 3: Integration & AI
- Extend `test_turn_flow_with_ai.gd` to call `execute_turn()` explicitly
- Add `request_move_to_coord()` calls to movement tests
- Wire up `set_unit_controlled_by_player()` assertions
- **Estimated effort:** 1 hour, **Coverage gained:** 9 functions

### Phase 4: GUI
- Simple signal-driven tests for `update_available_actions()`
- **Estimated effort:** 0.5 hours, **Coverage gained:** 1 function

---

## Why These Tests Are Missing

1. **Setters without side effects** — Often assumed to be trivial (e.g., `set_goal_manager()`)
   - **Solution:** Reference them with `auto_free(unit).set_goal_manager(...)` in dependent tests

2. **Query methods returning data** — Assumed covered if the data is used elsewhere
   - **Solution:** Explicit assertions on return values in focused unit tests

3. **Command pattern repetition** — 10 similar command subclasses with identical signatures
   - **Solution:** Single parameterized test with fixture array

4. **AI & integration logic** — Tested implicitly in gameplay integration tests
   - **Solution:** Extract deterministic AI behavior into dedicated test

---

## Validation & Next Steps

After implementation:

```powershell
# Run coverage check
python scripts/check_function_tests.py

# Full test suite
pwsh -File scripts/run_tests.ps1

# Validate with TODOs
pwsh -File scripts/validate.ps1 -UpdateTodos
```

---

## Recommendations for Future Gaps

1. **Unit Tests First:** Require all public methods to have a corresponding test reference within 2 commits
2. **Simplify Naming:** Use function name directly in test (not synonym or paraphrase)
3. **Parameterized Coverage:** For similar classes/methods, use fixtures to reduce duplication
4. **Automate Reporting:** Extend `check_function_tests.py` to:
   - Suggest which file should test each function
   - Flag recently-added functions not yet tested
   - Generate HTML coverage report with missing function list

---

## Related Files

- Test runner: `scripts/run_tests.ps1`
- Coverage checker: `scripts/check_function_tests.py`
- Existing test patterns: `tests/test_input_commands.gd`, `tests/test_unit_system.gd`
- Agent guide: `AGENTS.md` (architecture & testing principles)
