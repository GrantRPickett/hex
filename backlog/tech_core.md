# Backlog: Technical Core
Meeting: 2026-03-08 | Participants: Godot Dev, Godot QA, Architect

| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Fix failing tests in `reports/report_1191` | **L** | [ ] | **QA:** "Critical path. CI is currently red. Prevents verification of Omega Trial." |
| **[MUST]** Audit `weather_manager.gd` integration | **M** | [ ] | **Arch:** "Ensure no singleton leakage. Must align with `GameSession` lifecycle." |
| **[MUST]** Add tests for `CommandResult` error propagation | **S** | [x] | **Dev:** "Verify UI displays failures. Essential for player feedback loop." |
| **[MUST]** Refactor `EventBus` for weather state hooks | **S** | [x] | **Arch:** "Provide clean seams for visual/audio cues without tight coupling." |
| **[SHOULD]** Address 100% function coverage mandate | **XL** | [ ] | **QA:** "Focus on core `Gameplay/` services first. See `backlog/tech_debt_coverage.md`." |
| **[MUST]** Implement Weather state persistence in Saves | **S** | [x] | **Dev:** "Include current/forecast pressures in Game Memento." |
| **[SHOULD]** Add feedback for Weather Channeling conflict | **S** | [x] | **Dev:** "Show message when attempting to channel while already active." |
| **[COULD]** Resolve Location exploration tracking | **S** | [ ] | **ND:** "Determine if exploration state should be per-faction." |
| **[MUST]** Audit `UnitManager` signals for potential leaks | **XS** | [x] | **Arch:** "Verify cleanup on level transition." |
| **[SHOULD]** Unit component verification in `LevelManager` | **XS** | [x] | **QA:** "Ensure all spawned units have mandatory components (CombatProfile, etc)." |
| **[SHOULD]** Implement unit mocking helper in `base_test_suite.gd` | **S** | [x] | **QA:** "Streamline creation of dummy units for 100% coverage goal." |
| **[COULD]** Python: Dialogue file usage auditor script | **XS** | [x] | **Dev:** "Detect and report unused .dialogue files in resources." |
