## 1. Research & Design
- [ ] 1.1 Finalize hard-save data structure in `SaveManager`
- [ ] 1.2 Design the rotation logic for the 3 buffered slots

## 2. Implementation - SaveManager
- [ ] 2.1 Add `hard_save` slot management to `SaveManager`
- [ ] 2.2 Implement `trigger_hard_save()` with timestamp logging and memento flushing
- [ ] 2.3 Implement `load_hard_save(slot_index)` for revert functionality and memento flushing

## 3. Implementation - Level Selection
- [ ] 3.1 Update `level_select.gd` to call `SaveManager.trigger_hard_save()` before starting a level
- [ ] 3.2 Ensure inventory management changes are committed to the world state before hard-save

## 4. Implementation - Recovery & Revert
- [ ] 4.1 Update `LevelManager` or `GameSession` to utilize hard-save for reset/quit scenarios
- [ ] 4.2 Add "Continue" button logic to `title_screen.gd` that loads the latest soft-save
- [ ] 4.3 Add a session flag (e.g., `is_in_level`) to the soft-save to validate "Continue" eligibility
- [ ] 4.4 Implement `recovery_menu.gd` to display and select hard-save slots
- [ ] 4.5 Integrate "Recovery" button into Title Screen or Options
- [ ] 4.6 Add confirmation dialogs for state-reverting actions

## 5. Verification
- [ ] 5.1 Write unit tests for `SaveManager` hard-save rotation
- [ ] 5.2 Write unit tests for timestamp accuracy
- [ ] 5.3 Manual verification of recovery flow
