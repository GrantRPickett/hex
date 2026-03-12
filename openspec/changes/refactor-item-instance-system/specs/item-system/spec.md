# Capability: Item System

The Item System provides a way to define, instance, and track items within the game world, supporting inventories, loot, and persistence.

## ADDED Requirements

### Requirement: Template-Instance Separation

The system SHALL separate static item data (templates) from dynamic item state (instances) to prevent memory overlap and reduce save file size.

#### Scenario: Spawning unique instances

- [ ] **WHEN** the system creates two items from the same template ID
- [ ] **THEN** both items SHALL have identical base stats but unique UUIDs
- [ ] **AND** modifying one item (e.g., equipping) SHALL NOT affect the other

### Requirement: Item Registry

The system SHALL provide a central registry to index all available item templates and manage instance creation.

#### Scenario: Fetching template by ID

- [ ] **WHEN** the system requests an item template by its ID
- [ ] **THEN** the system SHALL return the corresponding `ItemTemplate` resource
- [ ] **AND** the resource SHALL be read-only

#### Scenario: Creating an instance

- [ ] **WHEN** the system creates an instance from a template ID
- [ ] **THEN** the system SHALL return a new `InventoryItem` instance linked to that template
- [ ] **AND** the instance SHALL have a newly generated UUID

### Requirement: Item Persistence

Item instances SHALL be serializable and restorable, maintaining their links to templates and their unique instance state.

#### Scenario: Serialization and Restoration

- [ ] **WHEN** an item instance is saved
- [ ] **THEN** only the `template_id` and unique state SHALL be stored
- [ ] **WHEN** the item instance is loaded
- [ ] **THEN** the system SHALL reconstruct the `InventoryItem` and re-link it to its template via the `ItemRegistry`
