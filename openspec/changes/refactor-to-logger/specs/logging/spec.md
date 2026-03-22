## ADDED Requirements
### Requirement: Centralized Logging
The system SHALL use a centralized Logger class for all console output, replacing raw print statements.

#### Scenario: Info Logging
- **WHEN** general application flow information needs to be recorded
- **THEN** the system must use the Logger's info-level logging method rather than `print()` or `print_debug()`

### Requirement: Categorized Logging
The logging system SHALL support categorized logs (e.g., AI, COMBAT, UI) and allow for centralized toggling of these categories.

#### Scenario: Category Toggled Off
- **WHEN** the `AI` log category is disabled in the central configuration
- **THEN** any messages sent to the `Logger` under the `AI` category MUST NOT be printed to the console

#### Scenario: Error and Warning Visibility
- **WHEN** reporting an error or warning
- **THEN** the system must use the Logger rather than `printerr()`, `push_error()`, or `push_warning()`, and these MUST generally bypass toggles unless specifically configured otherwise.

### Requirement: Granular Category Toggling
The logging system SHALL support categorizing log messages and toggling individual categories sequentially on or off from a central location.

#### Scenario: Suppressing Specific Logs
- **WHEN** the `AI` logging category is set to disabled
- **THEN** any info or debug messages logged under the `AI` category MUST NOT be printed to the console

#### Scenario: Error Logging
- **WHEN** an error or exceptional condition occurs
- **THEN** the system must use the Logger's error-level logging method to ensure proper visibility
