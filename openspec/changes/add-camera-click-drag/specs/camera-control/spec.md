## ADDED Requirements
### Requirement: Camera Panning (Drag)
The system MUST allow users to pan the camera by clicking and dragging on invalid movement areas (empty cells or out-of-range cells).

#### Scenario: Panning on empty space
- **GIVEN** a player is on the hex grid
- **WHEN** the mouse is pressed on a cell that is NOT a valid movement target
- **AND** the mouse is moved while held
- **THEN** the camera SHALL shift its position by the relative mouse movement delta.

### Requirement: Drag Dead Zone
The system SHALL have a small deadzone for dragging to prevent panning on unintentional mouse jitter during a click.

#### Scenario: Jitter suppression
- **GIVEN** a mouse button press
- **WHEN** the mouse moves less than 5 pixels
- **THEN** no camera panning SHALL occur.
