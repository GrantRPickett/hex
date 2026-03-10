# Refactoring Backlog

## Longest Functions (Priority 1)
- [x] `level/level_row_validator.gd`: `_validate_task_rows` (Refactored to `TaskRowValidator.validate`)
- [x] `GUI/unit_details_panel.gd`: `update_details` (Refactored into helper methods)
- [x] `level/level_auto_fix_service.gd`: `_repair_tasks` (Refactored to `TaskRepairer.repair`)
- [x] `Menus/settings_menu.gd`: `setup` (Refactored into helper methods)
- [x] `GUI/actions_panel.gd`: `_build_attribute_grid` (Refactored into helper methods)
- [x] `tests/test_level_row_loader.gd`: `test_apply_rows_populates_spawns_and_entries` (Refactored into helper methods)
- [x] `Gameplay/map/reachable_state_calculator.gd`: `calculate` (Refactored into helper methods)
- [x] `GUI/HUD/hud_component_factory.gd`: `_populate_right_column` (Refactored into helper methods)
- [ ] `Autoloads/weather_manager.gd`: `get_weather_info` (72 lines)
- [ ] `Gameplay/targets/target_spawner.gd`: `spawn_unit` (72 lines)

## Longest Files (Priority 2)
- [x] `Gameplay/turn/turn_controller.gd` (Refactored, now ~220 lines, was 454)
- [x] `Gameplay/narrative/task/task_controller.gd` (Refactored, now ~210 lines, was 405)
- [x] `Gameplay/narrative/task/task.gd` (Refactored, now ~170 lines, was 399)
- [x] `GUI/actions_panel.gd` (Refactored, now ~220 lines, was 483)
- [x] `GUI/hud.gd` (Refactored, now ~150 lines, was 336)
- [x] `Gameplay/targets/unit_action_manager.gd` (Refactored, now ~100 lines, was 331)
- [ ] `tests/test_unit_system.gd` (414 lines)
- [ ] `tests/test_input_commands.gd` (367 lines)
- [ ] `tests/test_morale_system.gd` (361 lines)
- [ ] `Menus/settings_menu.gd` (342 lines)

## Architectural Improvements (Priority 3)
- [x] **Data Type Safety**: Replaced complex Dictionaries (`ReachableState`, `UnitAction`) with Typed Classes.
- [x] **Autoload Audit**: Converted `GameConstants` and `FilePaths` to static `class_name` based utility classes.
- [ ] **Scene-First UI**: Refactor code-heavy UI generation into reusable `.tscn` templates.
- [x] **Typed Event System**: Replace string-based event types with Enums or specific signals.
- [x] **Coordinate Abstraction**: Centralize grid coordinate logic into a `GridService`.

## Progress
- [x] Create refactoring backlog artifact.
- [x] Refactor `GUI/unit_details_panel.gd`: `update_details`.
- [x] Refactor `Menus/settings_menu.gd`: `setup`.
- [x] Refactor `GUI/actions_panel.gd`: `_build_attribute_grid`.
- [x] Refactor `Gameplay/map/reachable_state_calculator.gd`: `calculate`.
- [x] Refactor `GUI/HUD/hud_component_factory.gd`: `_populate_right_column`.
- [x] Refactor `tests/test_level_row_loader.gd`: `test_apply_rows_populates_spawns_and_entries`.
- [x] Extracted `ActionLabelFormatter` logic from `ActionsPanel`.
- [x] Refactor `Gameplay/turn/turn_controller.gd`: extracted `TurnQueueBuilder`.
- [x] Refactor `Gameplay/narrative/task/task_controller.gd`: extracted `TaskStageSpawner`.
- [x] Refactor `Gameplay/narrative/task/task.gd`: extracted `TaskProcessor`.
- [x] Refactor `GUI/actions_panel.gd`: extracted `ActionTargetHandler`.
- [x] Refactor `GUI/hud.gd`: extracted `HudActionExecutor`.
- [x] Refactor `Gameplay/targets/unit_action_manager.gd`: extracted `MoveAndInteractProvider`.
- [x] Implemented `ReachableState` typed class.
- [x] Implemented `UnitAction` typed class.
- [x] Converted `GameConstants` to static class.
- [x] Converted `FilePaths` to static class.
- [x] Fixed `setup` parameter mismatches in multiple files.
