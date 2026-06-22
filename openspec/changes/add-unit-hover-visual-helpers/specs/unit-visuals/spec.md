# unit-visuals Specification

## Purpose
The Unit Visuals capability handles decorative and informational animations for units, such as squash and stretch for active units and wiggle for hovered targets.

## Requirements

### Requirement: Active Unit Squash & Stretch
The system SHALL apply a continuous squash and stretch idle animation to the currently selected player unit.

#### Scenario: Selection Cycle
- **GIVEN** a player unit is selected
- **WHEN** the selection starts
- **THEN** the unit SHALL begin a squash and stretch loop (tweaking scale)
- **WHEN** the selection changes to another unit
- **THEN** the first unit SHALL reset to neutral scale (1,1)
- **AND** the new unit SHALL stop any wiggle and begin the squash and stretch loop

### Requirement: Hover Target Feedback
The system SHALL provide visual feedback on a unit when it is targeted by a hovered action button in the UI.

#### Scenario: Hovering Action Button
- **GIVEN** an action button for a unit is displayed
- **WHEN** the user hovers the button
- **THEN** the target unit SHALL perform a temporary wiggle animation (rotating/moving slightly)
- **AND** the wiggle SHALL stop and reset to neutral when the hover ends
- **AND** the unit's hex grid location SHALL be highlighted in a distinct color
