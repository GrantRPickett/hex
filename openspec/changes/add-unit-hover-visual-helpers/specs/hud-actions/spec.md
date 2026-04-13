## MODIFIED Requirements

### Requirement: Hover Visual Feedback
The system SHALL provide visual feedback on the hex grid when hovering UI elements that target specific locations or units.

#### Scenario: Hovering action target
- **GIVEN** a unit has an action targeting another unit
- **WHEN** the user hovers the action button in the HUD
- **THEN** the target unit's hex grid location SHALL be highlighted with an "action-target" color
- **AND** the highlight SHALL be removed when the hover exits or change to a different target
