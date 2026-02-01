## ADDED Requirements
### Requirement: ResourceTables exposes roster/loot/goal rows
Level spawn, loot, and goal data MUST be stored as row-style Resources (LevelRosterRow, LevelLootRow, LevelGoalRow) under dedicated folder roots so the ResourceTables addon can edit them as spreadsheets.

#### Scenario: Editing a roster row
- **GIVEN** a LevelRosterRow with fields `level_id`, `faction`, `unit_scene_path`, and `coord`
- **WHEN** a designer changes the unit scene or coordinate via ResourceTables and saves
- **THEN** the `.tres` row under `res://Resources/level_data/roster_rows/` is updated with the new values without touching gameplay scripts.

#### Scenario: Editing loot and goal rows
- **GIVEN** LevelLootRow and LevelGoalRow resources stored under `res://Resources/level_data/loot_rows/` and `res://Resources/level_data/goal_rows/`
- **WHEN** a designer updates item lists or goal scene references in the ResourceTables UI
- **THEN** the saved rows reflect the new data so level content stays in sync.

### Requirement: Template rows provide defaults
Each row type MUST ship with at least one template `.tres` under a `templates/` subfolder so designers can duplicate a ready-to-edit example from ResourceTables. Templates must demonstrate required fields (level_id, coord, linked scenes/items) and use placeholder values that make it clear they are references only.

#### Scenario: Duplicating a roster template
- **GIVEN** `res://Resources/level_data/roster_rows/templates/roster_row_template.tres`
- **WHEN** a designer opens it in ResourceTables and chooses Duplicate
- **THEN** the new file inherits the exported columns with placeholder values they can edit before assigning a real `level_id`.

#### Scenario: Template coverage for loot/goals
- **GIVEN** templates exist for loot and goal rows in their respective `templates/` subfolders
- **WHEN** a designer duplicates them
- **THEN** the resulting rows already include example item arrays or goal scene paths so the designer knows how to fill them out.

### Requirement: Row loader rebuilds runtime data
A loader/service MUST collect the row resources for a requested `level_id`, convert them into the runtime structures (`UnitRosterDefinition.spawn_entries`, `LootListDefinition.loot_entries`, `LevelGoalEntry[]`), and inject them into the level loading pipeline before gameplay begins.

#### Scenario: Building rosters for a level
- **GIVEN** multiple LevelRosterRow entries tagged with `level_id = "level_3"`
- **WHEN** gameplay loads `level_3`
- **THEN** the loader groups those rows by faction, converts them into `UnitRosterDefinition.spawn_entries`, and the level receives the expected roster definitions.

#### Scenario: Missing or invalid rows
- **GIVEN** a level with no loot rows
- **WHEN** the loader runs
- **THEN** it produces an empty `LootListDefinition` (or null) and reports a warning so designers know the table is empty without crashing gameplay.





