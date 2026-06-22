# Change: Quest Item Persistence and Survival Flow

## Why

The current system routes quest items to the player stash at the end of the level, which prevents mid-level "Hot Potato" or "Capture the Flag" style quest flows where an item must be recovered from or defended by specific units. Furthermore, duration-based tasks (e.g., "Survive for 5 turns") lack correct attribution for the winning faction when no specific unit interaction occurs.

## What Changes

- **Quest Item Persistence**: Refactor `InventoryItem. quest` behavior to allow items to remain in unit inventories during a level.
- **Always-Drop Rule**: Modify `UnitDeathHandler` to ensure items with the `quest` flag are always dropped as loot on death, bypassing difficulty-based routing pools.
- **Mid-Stage Unit Rewards**: Update `TaskController` to grant item rewards directly to the unit inventory of the `actor` who completed the task.
- **Survival Task Attribution**: Update `Task.gd` to correctly attribute completion to the `owning_faction` for duration-based tasks that have no specific actor (e.g., countdowns/survival).
- **New Test Level**: Create `quest_competition.json` to verify the "Explore -> Recover -> Defend/Survive" flow.

## Impact

- Affected specs: `specs/quests/spec.md` (NEW), `specs/loot/spec.md` (NEW)
- Affected code: `UnitDeathHandler.gd`, `TaskController.gd`, `Task.gd`, `InventoryItem.gd`
