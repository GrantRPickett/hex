## ADDED Requirements

### Requirement: Flat Level Resource Output
The level generation system SHALL output all generated `.tres` files into a single directory per level.

#### Scenario: Successful flat generation
- **WHEN** `json_to_tres.py` is executed with a valid level JSON
- **THEN** all `.tres` files are created directly in `res://GeneratedLevels/<level_id>/`
- **AND** no subdirectories are created within that folder

### Requirement: Graceful Conversion Failure
The level generation system SHALL log a warning and continue processing other resources if a specific resource fails to generate.

#### Scenario: Missing optional field
- **WHEN** a JSON entry is missing an non-critical field
- **THEN** the script logs a warning
- **AND** continues to generate the remaining resources

### Requirement: Idempotent Level Generation
The level generation system SHALL support rerunning on the same JSON file to update or complete the level resources.

#### Scenario: Rerunning on updated JSON
- **WHEN** the input JSON is updated and the script is rerun
- **THEN** existing `.tres` files are updated with new values
- **AND** new `.tres` files are created for added entries
