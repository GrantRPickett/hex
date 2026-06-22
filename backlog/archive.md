# Backlog Archive
*Updated: 2026-03-11*

## Technical Core (Archived)
| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[MUST]** Add tests for `CommandResult` error propagation | **S** | [x] | **Dev:** "Verify UI displays failures. Essential for player feedback loop." |
| **[MUST]** Refactor `EventBus` for weather state hooks | **S** | [x] | **Arch:** "Provide clean seams for visual/audio cues without tight coupling." |
| **[MUST]** Implement Weather state persistence in Saves | **S** | [x] | **Dev:** "Include current/forecast pressures in Game Memento." |
| **[SHOULD]** Add feedback for Weather Channeling conflict | **S** | [x] | **Dev:** "Show message when attempting to channel while already active." |
| **[MUST]** Audit `UnitManager` signals for potential leaks | **XS** | [x] | **Arch:** "Verify cleanup on level transition." |
| **[SHOULD]** Unit component verification in `LevelManager` | **XS** | [x] | **QA:** "Ensure all spawned units have mandatory components (CombatProfile, etc)." |
| **[SHOULD]** Implement unit mocking helper in `base_test_suite.gd` | **S** | [x] | **QA:** "Streamline creation of dummy units for 100% coverage goal." |
| **[MUST]** Fix AI `move_to_enemy` failing precondition | **S** | [x] | **Dev:** "AI fails to `confirm_move` after `request_move_to_coord`. Needs frame-delay or state check." |
| **[SHOULD]** Prevent AI from attacking units with 0 WP | **XS** | [x] | **QA:** "AI targets units that are already defeated/retreating. Needs health check in evaluators." |
| **[MUST]** Fix `PrimaryActionCommand` success reporting | **XS** | [x] | **Dev:** "Reports success even when `request_move_to_coord` fails (e.g. Out of Bounds)." |
| **[COULD]** Add item names to loot interaction logs | **XS** | [x] | **QA:** "Logs show 'Unnamed Item' during successful loot. Ensure `item_name` is passed to interaction handler." |
| **[COULD]** Python: Dialogue file usage auditor script | **XS** | [x] | **Dev:** "Detect and report unused .dialogue files in resources." |
| **[MUST]** Audit Roster Sync for retreated/dead units | **M** | [x] | **Dev:** "`RosterManager.sync_from_combat` misses units removed from `UnitManager`. Leads to stale roster state (e.g. 6/6 units when one should be dead/retreated)." |
| **[MUST]** Fix `AutoBattleService` invalid unit handling | **S** | [x] | **Dev:** "Turn processing fails if unit is freed during AI await. Needs validity check after `execute_turn`." |
| **[SHOULD]** Fix Morale baseline recalculation bug | **XS** | [x] | **Arch:** "`MoralePanel` recalculates 'initial' max WP when units are removed, shifting the retreat threshold incorrectly." |
| **[MUST]** Investigate 5/6 inventory display discrepancy | **M** | [x] | **QA:** "Inventory shows 5 units when 6 are in roster. Likely due to invalid instances in `RosterManager._loaded_units` surviving combat transitions." |

## Product & UX (Archived)
| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[SHOULD]** Create `Documentation/PLAYER_QUICKSTART.md` | **M** | [x] | **CV:** "Must explain hex distance and Command cost clearly." |
| **[SHOULD]** Create `Documentation/MORALE_DESIGN.md` | **S** | [x] | **ND:** "Bridge narrative and mechanics. Document thresholds." |
| **[SHOULD]** Add "Customer Voice" review for `Morale` system | **S** | [x] | **CV:** "Is the tension 'cozy' or just 'stressful'?" |
| **[SHOULD]** Update `ARCHITECTURE.md` for new flows | **S** | [x] | **Arch:** "Detail Journal vs Task state persistence." |
| **[COULD]** Add tooltips to Morale Panel labels | **XS** | [x] | **CV:** "Explain the retreat thresholds (10%/20%/30%) based on difficulty." |
| **[COULD]** UI Feedback for Difficulty changes | **XS** | [x] | **Dev:** "Notify player or log when difficulty is swapped in Settings." |
| **[SHOULD]** Add "Unit Stat" flavor tooltips to details panel | **S** | [x] | **CV/ND:** "Explain what Grit/Flow/etc. actually represent in lore." |
| **[COULD]** Stress level color coding in Unit Details | **XS** | [x] | **ND:** "Visual urgency as units approach breaking point." |

## Narrative & Aesthetics (Archived)
| Task | Size | Status | Notes |
| :--- | :--- | :--- | :--- |
| **[COULD]** Review `WeatherAttribute.gd` flavor strings | **XS** | [x] | **ND:** "Avoid clinical descriptions; favor 'mood' over 'stats'." |
| **[COULD]** Audit hex-grid overlay color contrast | **S** | [x] | **Art:** "Accessibility: Colorblind-safe palettes for terrain types." |
| **[COULD]** Narrative review of 'Omega Trial' dialogue | **S** | [x] | **ND:** "Align auto-generated dialogues with local lore." |
| **[COULD]** Localize hardcoded weather metaphors | **XS** | [x] | **Dev:** "Move metaphors in `WeatherManager.WEATHER_METADATA` to `tr()` calls." |
| **[COULD]** Camera shake trigger hook for low morale | **S** | [x] | **Art/Dev:** "Add signal to EventBus for when WP < 20% to allow juice hooks." |
