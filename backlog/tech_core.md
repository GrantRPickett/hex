# Backlog: Technical Core

Meeting: 2026-03-08 | Participants: Godot Dev, Godot QA, Architect

| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Branching Mission Outcomes (Fail Forward) | **L** | [ ] | **Arch:** "Requires 'MissionState' to be persisted in SaveManager, not just ephemeral." / **ND:** "New story paths on mission failure." |
| **[MUST]** Fix failing tests in `reports/report_1191` | **L** | [ ] | **QA:** "Critical path. CI is currently red. Prevents verification of Omega Trial." / **Dev:** "Likely a race condition in `CombatSystem` signal cleanup. PO: Block all PRs until Green." |
| **[MUST]** Audit `weather_manager.gd` integration | **M** | [ ] | **Arch:** "Ensure no singleton leakage. Must align with `GameSession` lifecycle." / **Dev:** "Needs to handle state restoration after undo/redo." |
| **[SHOULD]** GraveyardService for Fallen Units | **M** | [ ] | **ND:** "Needs to store 'last words' or 'cause of death' for the final chronicle." / **QA:** "Track dead units for narrative epilogues." |
| **[SHOULD]** Address 100% function coverage mandate | **XL** | [ ] | **QA:** "Target core `Gameplay/` services first. Use `assert_signal_emitted` for all bus events." / **QA:** "Focus on core `Gameplay/` services first. See `backlog/tech_debt_coverage.md`." |
| **[SHOULD]** Persistent Grid Damage (Level Mementos) | **M** | [ ] | **Arch:** "Requires a robust Serialization schema to avoid bloat." / **ND:** "World persistence for destruction/burn states. Use it to tell a story of the battle's aftermath." |
| **[SHOULD]** Optimize GridVisuals & Selection Highlighting | **M** | [x] | **Arch:** "Consider a MultiMeshInstance or custom shader to offload logic from CPU." / **Dev/QA:** "Performance drops during multi-unit hover/selection." / **PO:** "Crucial for 'Premium Feels' objective; target 60FPS on target hardware." |
| **[SHOULD]** Decouple UnitManager from TerrainMap via GridQueryInterface | **L** | [x] | **Arch:** "Essential for future multi-grid or sub-grid support (e.g., inside buildings)." / **Dev/Arch:** "Refactor for better testability and isolation." / **PO:** "De-risks future scope expansions related to verticality." |
| **[SHOULD]** Detailed Combat Preview Tooltips | **M** | [ ] | **CV:** "Must avoid 'math-poverty'; use icons for stat pairs (Grit/Flow) to reduce cognitive load." / **QA:** "Show breakdown of Grit/Flow math to increase transparency." |
| **[SHOULD]** In-Game Stat Glossary (Journal Integration) | **S** | [ ] | **CV:** "Essential for players coming from traditional D&D who find paired stats confusing." / **Doc:** "Accessible reference for the Six-Stat model." |
| **[SHOULD]** Optimize `SaveManager` state capture frequency | **M** | [x] | **Arch:** "Logs show excessive saving on minor UI events (selections). Needs debounce or event filtering." |
| **[COULD]** Create placeholder sound/visual weather cues | **M** | [ ] | **Art:** "Need particle hooks for rain/heatwave in MapController." / **Sound:** "Transition faders for wind howling." |
| **[COULD]** Ambience Zone Generation for Map Generator | **M** | [ ] | **Sound:** "Spatial 2D audio nodes should be procedurally placed near terrain features like water." / **Art/PyDev:** "Extend Python tool to include audio trigger zones." |
| **[COULD]** Standardize Localization Export/Import Pipeline | **L** | [ ] | **PyDev:** "Standardize on `.csv` or `.pot`; automate extraction from `.gd` and `.tscn` files." / **Doc:** "Needs a clear 'Developer-to-Translator' handover guide." |
| **[COULD]** Asset Audit & Renaming Tool | **S** | [ ] | **PyDev:** "Utility to enforce naming conventions in `Resources/Audio`." / **Art:** "Helpful for batch importing sounds from external libraries." |
| **[COULD]** Resolve Location exploration tracking | **S** | [ ] | **ND:** "Determine if exploration state should be per-faction." |

| **[SHOULD]** Refactor High-Complexity Functions | **L** | [ ] | **Arch:** "Address top candidates in `backlog/complexity_backlog.md` (e.g., `_process_auto_turn`, `on_round_changed`)." / **QA:** "Reduce nesting to improve test reliability." |
| **[MUST]** Code starting weather into JSON | **S** | [ ] | **Dev:** "Expose initial weather configuration in level data." |
| **[SHOULD]** Decide weather effects and implementation | **L** | [ ] | **Dev/Arch:** "Define mechanical impacts of different weather states." |
| **[SHOULD]** Decide terrain state transition logic | **L** | [ ] | **Dev:** "Codify how terrain changes (e.g., fire, water soak)." |
| **[SHOULD]** Refine neutral priority weights | **M** | [ ] | **AI:** "Neutral units should prioritize peaceful interaction over combat." |
| **[SHOULD]** Link loyalty changes to turn order | **M** | [ ] | **Arch:** "Dynamic re-ordering of turn initiative based on loyalty shifts." |