## ADDED Requirements

### Requirement: Location Exploration

The system SHALL allow units to explore locations if they have an active exploration task.

#### Scenario: Explore action availability

- **GIVEN** an active objective with a stage containing an "explore" task for a specific location
- **WHEN** a player-controlled unit is on the same coordinate as the location
- **THEN** the Action Panel SHALL display an "Explore" button.

### Requirement: Opposed Exploration Check

Exploring a location SHALL require an opposed check if configured on the task.

#### Scenario: Successful exploration check

- **GIVEN** a unit with attribute "grit" of 5
- **AND** an explore task requiring "grit" with opposition value 3
- **WHEN** the unit performs the explore action
- **THEN** the task progress SHALL increase by 2 (5 - 3).
