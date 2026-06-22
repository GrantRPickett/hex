## ADDED Requirements

### Requirement: Quest Item Loot Priority

The system SHALL ensure that items marked with the `quest` flag are dropped as loot on the map when the unit holding them is defeated, regardless of difficulty-based routing rules.

#### Scenario: Dropping item on high difficulty

- **GIVEN** the game difficulty is set to "Hard" or "Survivor"
- **AND** an ENEMY unit is holding a `quest` item
- **WHEN** the unit is defeated
- **THEN** the `quest` item SHALL be spawned as loot on the unit's death coordinate
- **AND** it SHALL NOT be added to the routing pool.
