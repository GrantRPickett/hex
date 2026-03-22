## ADDED Requirements
### Requirement: Batch Animation Mode
The system SHALL provide a "Batch" animation speed setting that buffers unit movement and action animations during automated sequences.

#### Scenario: Round-end batch execution
- **GIVEN** the animation speed is set to "Batch"
- **AND** the game is in "Auto Act" mode
- **WHEN** multiple units perform actions during a round
- **THEN** their animations SHALL be buffered
- **AND** all buffered animations SHALL execute simultaneously when the round ends

#### Scenario: Invisible state updates
- **GIVEN** the animation speed is set to "Batch"
- **WHEN** a unit's coordinate is updated during a round
- **THEN** the logical game state SHALL reflect the new coordinate immediately
- **AND** other units SHALL be able to interact with it based on the updated coordinate
- **AND** the visual update SHALL be deferred to the batch execution
