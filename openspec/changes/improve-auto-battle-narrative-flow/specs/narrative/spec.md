# narrative Specification

## Purpose
The narrative system manages dialogue, barks, and story-driven interactions.

## ADDED Requirements
### Requirement: Interaction Log Integration
The narrative system SHALL append all dialogue lines and barks to the Interaction Log Panel for persistent tracking.

#### Scenario: Logging mode
- **WHEN** a dialogue line is processed
- **THEN** the text SHALL be sent to the Interaction Log Panel.
