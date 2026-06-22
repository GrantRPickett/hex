# auto-battle Specification

## Purpose
The auto-battle system allows the game to automatically execute unit turns based on AI priorities.

## ADDED Requirements
### Requirement: UI Suppression
The auto-battle system SHALL suppress intrusive UI elements (like dialogue balloons) that require user input to dismiss.

#### Scenario: Dialogue balloon skipped
- **GIVEN** auto-battle mode is active
- **WHEN** a narrative dialogue or combat bark is triggered
- **THEN** the dialogue balloon SHALL NOT be shown.

### Requirement: Universal Interaction Log
The system SHALL provide a persistent log of narratively significant interactions, regardless of whether auto-battle is active.

#### Scenario: Real-time logging (Auto-battle)
- **GIVEN** auto-battle mode is active
- **WHEN** a unit performs an action with narrative feedback
- **THEN** a formatted entry SHALL appear in the Interaction Log Panel.

#### Scenario: Real-time logging (Manual)
- **GIVEN** auto-battle mode is NOT active
- **WHEN** a dialogue is triggered
- **THEN** the dialogue balloon SHALL be shown
- **AND** a formatted entry SHALL also appear in the Interaction Log Panel.
