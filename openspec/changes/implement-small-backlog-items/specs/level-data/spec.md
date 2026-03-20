# level-data Specification

## Purpose
Define the structure and content of level data resources, ensuring consistent loading from JSON to Godot TRES.

## Requirements
### Requirement: Starting Weather Configuration

The level data SHALL include an optional `starting_weather` field to set the initial environmental state.

#### Scenario: Set initial weather
- **GIVEN** a level JSON with `"starting_weather": "Rain"`
- **WHEN** the level is loaded
- **THEN** the initialization system SHALL set the environment to "Rain" state.
