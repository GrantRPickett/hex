# controller-input Specification

## Purpose
The `controller-input` capability defines how the system handles physical controller (joypad) input, including context-aware navigation and standard action mapping.

## ADDED Requirements

### Requirement: Context-Aware Input Modes
The system SHALL maintain a global input mode that determines which commands are valid and how UI focus is managed.

#### Scenario: Menu navigation mode
- **GIVEN** a menu is open
- **WHEN** the Input Mode is set to `MENU`
- **THEN** D-pad and Left Stick inputs SHALL navigate UI focus instead of map cursor.

### Requirement: Standard Controller Mapping
The system SHALL provide default controller bindings for all core gameplay actions.

#### Scenario: Camera rotation via triggers
- **WHEN** the Left or Right Trigger is pressed
- **THEN** the camera SHALL rotate left or right respectively.

#### Scenario: Selection cycle via bumpers
- **WHEN** the Left or Right Bumper is pressed
- **THEN** the active unit selection SHALL cycle to the previous or next unit.
