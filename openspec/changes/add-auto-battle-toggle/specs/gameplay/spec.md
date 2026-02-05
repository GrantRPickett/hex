## ADDED Requirements

### Requirement: Auto Battle Toggle Control
Players MUST be able to enable or disable auto battle via an explicit HUD control at any point during gameplay and the control MUST reflect the current state.

#### Scenario: Toggle from HUD button
- **GIVEN** the HUD is visible and no modal dialogue is active
- **WHEN** the player presses the Auto Battle button while it is off
- **THEN** the HUD highlights the button as active, emits an "auto_battle_enabled" signal, and hides contextual hint text until auto battle ends

#### Scenario: Cancel auto battle mid-level
- **GIVEN** auto battle is currently active
- **WHEN** the player presses the Auto Battle button again or a bound hotkey
- **THEN** the HUD clears the active highlight, emits an "auto_battle_disabled" signal, and manual input becomes available after the current AI action finishes

### Requirement: Player AI Delegation
When auto battle is active, every player-controlled turn MUST be resolved through AIController logic until the toggle is disabled, and manual control MUST resume without desync.

#### Scenario: Player turn resolved by AI
- **GIVEN** auto battle is active and a player-controlled unit is selected for a turn
- **WHEN** the turn controller emits `turn_ready`
- **THEN** the system suppresses manual input prompts, invokes AIController.execute_turn for that unit, and completes the turn without player interaction

#### Scenario: Auto battle cancel resumes manual control
- **GIVEN** auto battle was active but was toggled off while an AI-controlled player action is underway
- **WHEN** the pending AI action finishes
- **THEN** the next player turn surfaces `turn_ready`, restores HUD interactions, and no additional AI commands execute until auto battle is re-enabled

### Requirement: Unsupported Action Reporting
The game MUST surface diagnostics when auto battle attempts a player-only action that AIController cannot execute so that QA can audit missing behaviors.

#### Scenario: Unsupported command warning
- **GIVEN** auto battle is active and AIController selects a player action type that lacks an AI implementation (e.g., a story ability)
- **WHEN** the action handler detects the unsupported type
- **THEN** the HUD flashes a warning banner listing the unit name and action type, logs the event to the debug console, and skips the unsupported command without crashing
