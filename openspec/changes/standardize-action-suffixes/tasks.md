## 1. Indicator Simplification
- [ ] 1.1 Update `CombatSystem.get_group_status_suffix` to return only the single best symbol.
- [ ] 1.2 Update `CombatSystem.get_group_task_quality_suffix` to return only the single best symbol.
- [ ] 1.3 Update `test_action_label_formatter.gd` to expect single-symbol suffixes instead of lists.

## 2. Formatting Uniformity
- [ ] 2.1 Refactor `ActionLabelFormatter.get_label` to ensure `CONVINCE` and `MOVE_AND_INTERACT` (Gather/Explore) actions apply suffixes in the same way as standard attacks.
- [ ] 2.2 Verify that the `format()` helper is used consistently for all multi-target actions.

## 3. UI Refinement
- [ ] 3.1 Update `ActionsPanel.gd` to ensure that when a specific target is selected for a multi-target action, the attribute grid accurately reflects that target's forecast.
- [ ] 3.2 Ensure the attribute grid refreshes correctly when switching between targets in the target selection menu.
