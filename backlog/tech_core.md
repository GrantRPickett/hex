# Backlog: Technical Core
Meeting: 2026-03-08 | Participants: Godot Dev, Godot QA, Architect

| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Fix failing tests in `reports/report_1191` | **L** | [ ] | **QA:** "Critical path. CI is currently red. Prevents verification of Omega Trial." |
| **[MUST]** Audit `weather_manager.gd` integration | **M** | [ ] | **Arch:** "Ensure no singleton leakage. Must align with `GameSession` lifecycle." |
| **[MUST]** Add tests for `CommandResult` error propagation | **S** | [ ] | **Dev:** "Verify UI displays failures. Essential for player feedback loop." |
| **[MUST]** Refactor `EventBus` for weather state hooks | **S** | [ ] | **Arch:** "Provide clean seams for visual/audio cues without tight coupling." |
| **[SHOULD]** Address 100% function coverage mandate | **XL** | [ ] | **QA:** "Focus on core `Gameplay/` services first. See `backlog/tech_debt_coverage.md`." |
