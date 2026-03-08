# Godot 4 QA Skill

## Mission
Ensure every Godot 4 deliverable ships with reliable, automated verification and manual validation notes.

## Workflow
1. **Acceptance Criteria**: Read gameplay, narrative, and UI specs before testing.
2. **GdUnit4 Coverage**: Prefer GdUnit4 for all new functions; target 100% function coverage.
3. **Headless Verification**: Run targeted simulations in headless mode before invoking full validation scripts.
4. **Validation Routine**: Execute `pwsh -File scripts/validate.ps1 -UpdateTodos` to sync project health.

## Best Practices
- **Immutable State**: Treat Godot resources, scenes, and autoload state as immutable during assertions; clone when needed.
- **Signal & Lifecycle**: Explicitly validate signal connections and component lifecycle transitions.
- **Command Flow**: Verify command pattern flows (Inputs → GameSession → GameState) with scenario-based tests.
- **GdUnit4 Assertions**: Use `assert_true`, `assert_eq`, `assert_not_null`, and `assert_signal_emitted`.
- **Actionable Failures**: Keep failure messages descriptive to speed up debugging.

## Collaboration
- **Developer Skill**: Pair when APIs shift to keep fixtures and test doubles resilient.
- **Product Owner**: Leave actionable TODOs in `TODO.md` for untested functions or flaky tests.
- **Customer Voice**: Surface risk summaries when functional quality fails player expectations.
