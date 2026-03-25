# hud-actions Specification

## Purpose

TBD - created by archiving change redesign-action-menu-layout. Update Purpose after archive.

## Requirements

### Requirement: Attribute Grid Layout

The system SHALL display attribute selection buttons in a 3x2 grid layout.

#### Scenario: Displaying paired stats

- **GIVEN** a unit is selecting an attribute for an action
- **WHEN** the attribute menu is shown
- **THEN** Grit and Flow SHALL be in the first column
- **AND** Gusto and Focus SHALL be in the second column
- **AND** Shine and Shade SHALL be in the third column

### Requirement: Compact Target Selection

The system SHALL provide a spatially efficient interface for selecting targets when multiple options are available.

#### Scenario: Multiple near targets

- **GIVEN** a unit has multiple near targets for an action
- **WHEN** the target selection menu is shown
- **THEN** the target list SHALL be displayed without overlapping the hexagonal grid.

