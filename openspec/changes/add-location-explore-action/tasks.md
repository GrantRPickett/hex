## 1. Research & Preparation

- [x] 1.1 Review current Task and ActionProvider implementations

## 2. Implementation

- [ ] 2.1 Update `TaskActionProvider.gd` to include `explore` tasks
- [ ] 2.2 Verify `Task.gd`'s `handle_event("explore", ...)` logic
- [ ] 2.3 Ensure "Explore" button appears in `ActionsPanel` via `UnitActionManager`

## 3. Verification

- [ ] 3.1 Create a test level with a location containing an explore task
- [ ] 3.2 Verify the "Explore" button appears when a player unit moves to the location
- [ ] 3.3 Verify clicking "Explore" performs the opposed check and updates task progress
