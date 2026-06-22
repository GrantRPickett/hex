## 1. Requirements & Design
- [ ] 1.1 Review existing task/stage specs and narrative code to confirm data owners for targets, bonuses, and stage transitions.
- [ ] 1.2 Define aggregation data model (pooled targets, hidden entries, carryover metadata) and persistence requirements.

## 2. Implementation
- [ ] 2.1 Teach TaskManager/Stage objects to register aggregated tasks, evaluate progress from pooled targets, and emit progress summaries for UI/save.
- [ ] 2.2 Add carryover logic on stage transitions, including optional-task gating and "Eliminate All" special-case behavior.
- [ ] 2.3 Support composite logic (OR goals, bonus progress) and multi-faction participation flags; ensure undo/save/load remain consistent.
- [ ] 2.4 Update HUD/task UI to display aggregated goals (nested targets, progress bars, loyalty summaries) without clutter.

## 3. Validation
- [ ] 3.1 Add automated tests covering pooled target completion, carryover persistence, composite branching, and bonus progress propagation.
- [ ] 3.2 Update designer documentation / localization entries describing aggregated task workflows.
