## ADDED Requirements

### Requirement: Hard-Save Trigger
The system SHALL create a "hard-save" record when a player selects a level to start from the level select menu, but BEFORE the target level scene is loaded.

#### Scenario: Level selection triggers hard-save
- **WHEN** the player clicks a level button in the level select menu
- **THEN** a hard-save of the current world state (inventory, roster, flags) is created and persisted to disk
- **AND** the level transition proceeds only after the save is completed

### Requirement: Save-State Isolation
The system SHALL clear all current soft-saves, mementos, and undo history whenever a hard-save is created or loaded. This prevents the player from using undo/redo to jump between different "timelines" or inconsistent world states.

#### Scenario: Hard-save clears undo history
- **WHEN** a hard-save is performed (manually or via level select)
- **THEN** the `SaveManager` memento history is flushed
- **AND** the current memento index is reset


### Requirement: Terrain State Capture
The system SHALL capture the current state of the game map and terrain in all mementos. This includes any dynamic manipulations (e.g., dried-up rivers, terrain type changes).

#### Scenario: Terrain change persistent through soft-save
- **WHEN** terrain is modified by a game event or skill
- **AND** a soft-save (memento) is created
- **AND** the game crashes and is resumed via "Continue"
- **THEN** the modified terrain state is correctly restored

### Requirement: Hard-Save Recovery
The system SHALL use the most recent hard-save as the definitive state for recovery if a player loses or chooses to explicitly quit a level via the UI.

#### Scenario: Restoring from hard-save on defeat
- **WHEN** the player is defeated in a level or chooses to quit to main menu
- **THEN** the game world state is reverted to the most recent hard-save
- **AND** any partial progress or consumable usage within that level is discarded

### Requirement: Soft-Save Continue (Crash Recovery)
The system SHALL provide a "Continue" option on the main menu if a valid soft-save (memento) from an active level session exists, allowing recovery from crashes or unexpected closures.

#### Scenario: Resuming after crash
- **WHEN** the game starts and a soft-save exists that indicates an active level session
- **THEN** the Title Screen displays an enabled "Continue" button
- **AND** clicking "Continue" restores the soft-save, placing the player back in the level at the last memento point

#### Scenario: No resumable session
- **WHEN** the game starts and no valid in-level soft-save exists
- **THEN** the Title Screen disables or hides the "Continue" button
- **AND** the player must choose between "New Game" or "Level Select" (Hard-Save)

### Requirement: Descriptive Metadata
Each hard-save record MUST include the creation timestamp, the current Level ID/Name, the total count of completed levels, AND the ID/Name of the most recently completed level. This provides maximum clarity for the player when choosing a recovery point.

#### Scenario: Save data contains context
- **WHEN** a hard-save is created
- **THEN** the Level ID (e.g., "dark_forest_1"), completion count (e.g., "5"), and last completed level (e.g., "Dark Forest Entrance") are stored along with the timestamp.

### Requirement: Hard-Save Selection UI (Recovery Menu)
The system SHALL provide a "Recovery" or "Load Save" menu (accessible from Options or Title) that allows players to see the 3 buffered slots with their metadata and choose which one to restore.

#### Scenario: Player reverts to a previous level start
- **WHEN** the player opens the "Recovery" menu
- **THEN** they see 3 entries with timestamps and level names
- **AND** selecting an entry restores that world state, clearing current session progress.
