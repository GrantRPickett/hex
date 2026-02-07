# journal Specification

## Purpose
TBD - created by archiving change add-journal-feature. Update Purpose after archive.
## Requirements
### Requirement: Journal Data
The system SHALL have a data structure for the journal that includes sections and entries.

#### Scenario: Journal Structure
- **GIVEN** the game has a journal
- **THEN** the journal SHALL be composed of sections, and sections SHALL be composed of entries.

### Requirement: Journal Persistence
The system SHALL persist the state of unlocked journal entries across game sessions.

#### Scenario: Unlocking an entry
- **GIVEN** a player has not unlocked a specific journal entry
- **WHEN** the player performs an action that unlocks the entry
- **THEN** the entry SHALL be marked as unlocked.
- **AND** when the game is saved and reloaded, the entry SHALL remain unlocked.

### Requirement: Journal UI
The system SHALL provide a user interface for viewing the journal.

#### Scenario: Viewing the journal
- **GIVEN** a player has unlocked at least one journal entry
- **WHEN** the player opens the journal UI
- **THEN** the unlocked entries SHALL be visible, organized by section.

