# Proposal: Refactor Navigation to AStar2D

## Why

The current manual Dijkstra implementation is becoming complex to maintain and lacks native optimizations. Moving to `AStar2D` provides better performance and a cleaner API for pathfinding.

## What Changes

- [x] Implement `AStar2D` graph management.
- [x] Integrate terrain weights and dynamic blockers.
- [x] Maintain BFS for flood-fill range calculations.

## Impact

- **BREAKING**: Pathfinding results may differ slightly due to AStar tie-breaking.
- Affected code: `MovementRangeCalculator.gd`, `Unit.gd`.
- **REFACTOR**: Replace manual A* loop in `MovementRangeCalculator.gd` with engine-level `AStar2D` pathfinding.
- **MODIFIED**: Update `find_path` to leverage `astar.get_id_path`.
- **MODIFIED**: Integrate terrain weights from `TerrainMap` into `AStar2D` point weights.
- **Performance**: Faster pathfinding for AI and player previews.
