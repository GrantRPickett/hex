## 1. Preparation
- [x] 1.1 Document existing function inventory in `design.md`
- [ ] 1.2 Identify point ID mapping strategy (`y * width + x`)

## 2. Implementation
- [x] 2.1 Add `_astar` member and map caching logic to `MovementRangeCalculator.gd`
- [x] 2.2 Implement Graph Rebuilding logic (`_ensure_astar_ready`)
- [x] 2.3 Refactor `find_path` to use `AStar2D.get_id_path`
- [x] 2.4 Implement dynamic state injection (blockers/threats) in `find_path`
- [ ] 2.5 Ensure `compute` (range) remains functionally parity with existing BFS

## 3. Verification
- [ ] 3.1 Run `res://tests/test_unit_system.gd`
- [ ] 3.2 Verify `test_unit_get_path_to_coord_allows_friendly_hexes` passes
- [ ] 3.3 Verify pathfinding still respects terrain weights (AStar vs Dijkstra comparison)
