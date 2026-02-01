## ADDED Requirements
### Requirement: ResourceTables exposes terrain/start/dialogue rows
Level terrain rows, player/neutral spawn positions, dialogue triggers, and level rotation/flags MUST be expressed via dedicated row Resource assets (LevelTerrainRow, LevelStartRow, LevelDialogueRow, LevelMetaRow) stored under predictable folders with templates for duplication.

#### Scenario: Editing terrain grid via ResourceTables
- **GIVEN** terrain rows live under es://Resources/level_data/terrain_rows/
- **WHEN** a designer tweaks a row (column index, tile type) inside ResourceTables and saves
- **THEN** the .tres row reflects the change without touching the old level_?_terrain_data.tres files.

#### Scenario: Editing player/neutral starts
- **GIVEN** LevelStartRow resources list level_id, action, slot_index, and coord
- **WHEN** a designer reorders or adds spawns via ResourceTables
- **THEN** the rows persist and can be reloaded into gameplay without editing the Level resource.

#### Scenario: Editing dialogue rows
- **GIVEN** LevelDialogueRow resources with exported fields mirroring LevelDialogueEntry (ids, names, timeline reference, flags)
- **WHEN** a designer changes the timeline path or repeatable flag via ResourceTables
- **THEN** the row saves and will be converted into a LevelDialogueEntry during load.

### Requirement: Row loader populates terrain/start/dialogue data
The row loader/service MUST regenerate LevelTerrainData.terrain_rows, player_starts, neutral starts, and dialogue entry arrays from the row files before the map builds.

#### Scenario: Loading terrain rows
- **GIVEN** LevelTerrainRow entries covering a 7×7 grid for level_3
- **WHEN** pply_rows_to_level(level_3) runs
- **THEN** level.terrain_data.grid_width/grid_height/terrain_rows match the row definitions and contain no inconsistent line lengths.

#### Scenario: Loading start/dialogue rows
- **GIVEN** LevelStartRow and LevelDialogueRow files for level_4
- **WHEN** the loader applies rows
- **THEN** level.player_starts and level.dialogue_entries contain entries derived from the rows, preserving slot order and dialogue metadata.

### Requirement: Level row validator checks bounds and overlaps
A validator MUST evaluate every row type after loading, emitting warnings/errors when:
- Terrain rows are missing, exceed grid bounds, or have inconsistent string lengths.
- Player/neutral starts overlap each other or enemy/goal coords.
- Dialogue rows reference invalid timelines or fall outside the grid.
- Metadata rows set invalid rotation/hex offset values.

#### Scenario: Detect overlapping spawns
- **GIVEN** two LevelStartRow entries sharing the same coord
- **WHEN** the validator runs
- **THEN** it reports a “duplicate start coordinate” error identifying the row resource path.

#### Scenario: Detect out-of-bounds dialogue trigger
- **GIVEN** a LevelDialogueRow with coord (9,9) on a 7×7 map
- **WHEN** validation runs
- **THEN** it adds an “out of bounds” warning referencing the dialogue row file and level id.

#### Scenario: Timeline reference enforcement
- **GIVEN** a LevelDialogueRow without 	imeline or 	imeline_path
- **WHEN** validation runs
- **THEN** it reports a missing timeline error so designers can fix the row before shipping.
