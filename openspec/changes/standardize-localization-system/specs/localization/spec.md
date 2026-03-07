# Localization Specification

## ADDED Requirements

### Requirement: Native Translation Support
The system SHALL use Godot's native `TranslationServer` and CSV-based translation tables for all UI and dialogue text.

#### Scenario: Locale switching
- **WHEN** the system locale is changed to "es"
- **THEN** all UI elements and dialogue lines show Spanish text from the translation table.

### Requirement: Automatic Dialogue ID Generation
The level generator SHALL automatically inject stable, unique Line IDs into generated `.dialogue` files.

#### Scenario: TRES generation with IDs
- **WHEN** a level JSON is converted to .tres
- **THEN** each line in the generated .dialogue files includes a static ID tag (e.g., `[ID:L12345]`).

### Requirement: Centralized String Management
All UI strings SHALL be managed in a centralized CSV file (`translations.csv`) rather than hardcoded in scripts.

#### Scenario: Adding new UI strings
- **WHEN** a new UI key is added to the CSV
- **THEN** it can be retrieved in GDScript using `tr("key")`.
