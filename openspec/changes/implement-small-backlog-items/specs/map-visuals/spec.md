# map-visuals Specification

## Purpose
Govern the visual representation of the hex grid and map elements.

## Requirements
### Requirement: Diverse Location Sprites

Key locations on the map SHALL be represented by unique, thematic sprites instead of generic placeholders.

#### Scenario: Special location display
- **GIVEN** a "Hidden Grove" location on the map
- **WHEN** rendered
- **THEN** it SHALL use a specific grove-themed sprite rather than a generic rock placeholder.
