# Targeted Cleanup TODOs (Generated April 14, 2026)

Focused on files flagged simultaneously by complexity, long-file, and long-function audits. Each item should preserve current behavior; capture before/after states with tests or scripted verifications prior to refactors.

## Gameplay/targets/unit.gd
- [x] Split `_ready` (complexity 22, lines 112-171) into discrete helpers so signal wiring, resource ownership, visual setup, and saved-item restoration each operate independently.
- [x] Refactor `update_visuals` (complexity 19, 67-line span 203-269) by extracting sprite readiness, custom-region handling, neutral/enemy region selection, and tint application helpers while keeping logging identical.
- [x] Introduce GdUnit4 tests referencing `_ready` and `update_visuals` by name to lock current signal registrations and sprite selection logic before further refactors.
- [x] Re-run `scripts/analyze_complexity.py` and `scripts/find_long_funcs.py` to confirm reductions without regressions.

## Gameplay/narrative/task/task_manager.gd
- [ ] Break `get_categorized_location_tasks` (complexity 19, lines 234-267) into smaller query helpers (e.g., filters per faction/biome) to drop nested branching.
- [ ] Tame `debug_complete_task` (length 71 lines 364-434) by extracting command building, validation, and progression steps; ensure debug-only pathways remain gated.
- [ ] Reduce total file size (currently 597 lines) by relocating shared task filters to a service or utility module with paired tests.
- [ ] Add or expand GdUnit4 coverage for new helpers plus regression checks for `get_active_tasks_for_target_ctx` (complexity 14) to ensure no task exposure changes.

## GUI/tasks_list_panel.gd
- [ ] Decompose `_update_display` (complexity 19, 66 lines 72-137) into separate methods for sorting, grouping, and rendering list entries to avoid cascading UI diff churn.
- [ ] Add focused GUI tests (mocking journal data) that assert rendered task ordering and status icons so UI refactors don't break "g"’s current workflows.
- [ ] Audit related signals and dependencies (journal manager, HUD refresh) before changes; document any coupling in `GUI/tasks_list_panel.gd` header comments.
- [ ] After cleanup, re-run `scripts/find_long_funcs.py` plus relevant UI regression scenes to ensure no layout regressions.
