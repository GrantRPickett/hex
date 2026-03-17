# Refined Discovery Infrastructure

Unify and generalize the discovery logic for units, loot, and tasks by creating a robust, reusable service that leverages existing manager APIs and hex utilities.

## User Review Required

> [!IMPORTANT]
> I am moving to a "Deep Reuse" architecture for discovery. Instead of parallel re-implementations in every class, `TargetDiscoveryService` will serve as the single source of truth for "what can this unit see or reach?". This resolves the brittle duplication issues and restores strict type safety.

## Proposed Changes

### [Unified Discovery Service]

#### [MODIFY] [TargetDiscoveryService.gd](file:///c:/Users/grant/Documents/github/hex/Gameplay/targets/discovery/target_discovery_service.gd)
- **Typed API**: Restore all class type hints (`Unit`, `Loot`, `Location`, `Task`, `TaskManager`, `LootManager`).
- **Generic Retrieval**:
  - `discover_nearby(center: Vector2i, radius: float, types: int, context: Dictionary) -> Dictionary`
  - `discover_reachable(lookup: Dictionary, types: int, context: Dictionary) -> Dictionary`
- **Internal Reuse**: Use `HexLib` for distance and existing manager lists (`get_all_loot`, `active_tasks`) to avoid redundant grid scans.

### [Callers]

#### [MODIFY] [LootEvaluator.gd](file:///c:/Users/grant/Documents/github/hex/Gameplay/turn/ai/loot_evaluator.gd), [TaskEvaluator.gd](file:///c:/Users/grant/Documents/github/hex/Gameplay/turn/ai/task_evaluator.gd)
- [RESTORE] Ensure `class_name` and proper preloads are present.
- Replace internal discovery loops with calls to the unified service.

#### [MODIFY] [LootActionProvider.gd](file:///c:/Users/grant/Documents/github/hex/Gameplay/targets/loot_action_provider.gd), [LocationActionProvider.gd](file:///c:/Users/grant/Documents/github/hex/Gameplay/targets/location_action_provider.gd)
- Consolidate common "nearby" and "reachable" logic into the service.

### [Verification Plan]

#### Automated Tests
- Run [test_fix_verification.gd](file:///c:/Users/grant/Documents/github/hex/tests/test_fix_verification.gd) to ensure the new API correctly identifies both adjacent and distant loot/tasks.
- Add a new test case targeting the generic discovery function directly to verify it correctly filters by type and handles duplicates.
