# gameplay-settings Specification

## Purpose
The `gameplay-settings` capability defines the configuration and behavior of core gameplay parameters that can be adjusted by the user, such as animation speed, difficulty, and automated behaviors.

## Requirements
### Requirement: Animation Speed Settings
The system SHALL provide multiple animation speed levels to allow users to customize the visual pacing of the game.

#### Scenario: Normal speed default
- **GIVEN** the game is started for the first time
- **WHEN** checking the animation speed setting
- **THEN** it SHALL be set to "normal"

#### Scenario: Fast speed multiplier
- **GIVEN** the animation speed is set to "fast"
- **WHEN** a unit move is animated
- **THEN** the duration SHALL be 25% of the base duration

### Requirement: Difficulty Scaling
The system SHALL support different difficulty levels that influence AI behavior and combat modifiers.

#### Scenario: AI scaling
- **GIVEN** the difficulty is set to "easy"
- **WHEN** the AI calculates a move
- **THEN** its base scores SHALL be scaled by 0.5
