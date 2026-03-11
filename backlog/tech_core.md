# Backlog: Technical Core
Meeting: 2026-03-08 | Participants: Godot Dev, Godot QA, Architect

| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Fix failing tests in `reports/report_1191` | **L** | [ ] | **QA:** "Critical path. CI is currently red. Prevents verification of Omega Trial." |
| **[MUST]** Audit `weather_manager.gd` integration | **M** | [ ] | **Arch:** "Ensure no singleton leakage. Must align with `GameSession` lifecycle." |
| **[SHOULD]** Address 100% function coverage mandate | **XL** | [ ] | **QA:** "Focus on core `Gameplay/` services first. See `backlog/tech_debt_coverage.md`." |
| **[COULD]** Resolve Location exploration tracking | **S** | [ ] | **ND:** "Determine if exploration state should be per-faction." |
| **[SHOULD]** Optimize `SaveManager` state capture frequency | **M** | [x] | **Arch:** "Logs show excessive saving on minor UI events (selections). Needs debounce or event filtering." |
