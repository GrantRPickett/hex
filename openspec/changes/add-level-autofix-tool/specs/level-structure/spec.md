## ADDED Requirements
### Requirement: Level auto-fix repairs blocking tiles
When the level validator flags impassable/out-of-bounds goals or start positions, the system MUST be able to compute deterministic fallback coordinates (nearest passable tile, respecting faction priority) and mutate the in-memory level payload before LevelBuilder spawns content. The repair logic must guard against infinite loops, avoid changing release builds unless the auto-fix flag is enabled, and log every applied fix with the originating row resource path.

#### Scenario: Impassable goal relocation
- **GIVEN** a level goal row that sits on lava (impassable)
- **WHEN** auto-fix runs with the flag enabled
- **THEN** it finds the closest passable coord by spiral/BFS search, updates the goal coord in the temporary level data, and logs the move as goal level_3_goal_1.tres row 12 -> (2,3) so gameplay can proceed.

#### Scenario: Overlapping start resolution
- **GIVEN** two player LevelStart rows sharing the same coord
- **WHEN** validation detects the overlap and auto-fix is enabled
- **THEN** the second start shifts to the next nearest free coord that is also passable and not already reserved by a goal/enemy spawn.

#### Scenario: Out-of-bounds neutral start
- **GIVEN** a neutral start row outside the terrain grid
- **WHEN** auto-fix runs
- **THEN** it clamps or repositions the coord inside the grid, reports the change, or marks the row as skipped if no passable tile can be found.

### Requirement: Auto-fix toggle and reporting
The validator/builder flow MUST expose a configuration toggle (per build or command invocation) that controls whether repairs are applied, and it must emit a structured repair report (console summary + JSON) capturing each fix, suggested manual change, and any rows it could not repair.

#### Scenario: Dev build auto-fix toggle
- **GIVEN** the QA CLI runs with --auto-fix-levels
- **WHEN** a level with impassable goals loads
- **THEN** gameplay uses the repaired coords, and the console states Applied 2 level repairs (details in reports/level_autofix.json).

#### Scenario: Release build keeps original data
- **GIVEN** the shipping build disables auto-fix
- **WHEN** the validator finds an impassable start
- **THEN** gameplay refuses to auto-repair, surfaces the blocking error, and aborts loading so production never hides data issues.

#### Scenario: Repair report contents
- **GIVEN** auto-fix moves a goal and drops a neutral start that had no valid tile
- **WHEN** the report is written
- **THEN** it lists both entries with their row file paths, original coords, chosen replacement coords (or null when removed), and user-facing instructions so designers can update the ResourceTables rows.
