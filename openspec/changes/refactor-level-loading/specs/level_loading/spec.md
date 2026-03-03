# Level Loading

## MODIFIED Requirements

#### Requirement: The level loading pipeline uses composition and flat entry objects instead of inheritance and wrapper rows

**Scenario:** A level is loaded containing units, loot, and tasks.

- **Given** valid JSON level data has been compiled into Godot resources
- **When** the `LevelRowLoader` loads `level_1`
- **Then** it directly loads `LevelUnitSpawnEntry`, `LevelLootEntry`, `LevelTaskEntry`, etc., arrays onto the `Level` object.
- **And** no intermediate ``*Row`` resources are used during loading.
